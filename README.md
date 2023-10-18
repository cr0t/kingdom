# Kingdom Elixir Workshop

It's a sample application made for the Elixir Brainwashing workshop.

The main goal of this app is to teach students about basics of GenServer and illustrate how BEAM applications work are being created in general.

## Step-by-Step

### Starting Point

This command creates a new Elixir project:

```console
mix new kingdom --sup
```

### Add Treasury module

It is based on GenServer behavior. The module does nothing yet, it only implements a single callback defined by the GenServer behaviour: `init/1`.

```elixir
defmodule Kingdom.Treasury do
  use GenServer

  def init(balance) do
    {:ok, balance}
  end
end
```

### Handle Adding, Subtracting, and Balance Actions

We implement a few more callbacks for our `Treasury` module to make useful to represent a balance.

```elixir
# ...

def handle_cast({:store, amount}, balance) do
  {:noreply, balance + amount }
end

def handle_cast({:withdraw, amount}, balance) do
  {:noreply, balance - amount}
end

def handle_call(:balance, _from, balance) do
  {:reply, balance, balance}
end

# ...
```

> [!note]
>
> We can already start using this server:
>
> ```console
> iex> {:ok, pid} = GenServer.start_link(Kingdom.Treasury, 0)
> {:ok, #PID<0.167.0>}
> iex> GenServer.cast(pid, {:store, 100})
> :ok
> iex> GenServer.call(pid, :balance)
> 100
> ```
>
> ...but it would be better to add some nice API for its internal clients.

### Introduce an API for the Treasury Module

To hide the implementation details, we will add client commands in the same module. We shall also use the module's name when spawning a new process via `start_link` to easily refer to this server inside of the application.

```elixir
defmodule Kingdom.Treasury do
  use GenServer

  ### Client API

  def open() do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def store(amount) do
    GenServer.cast(__MODULE__, {:store, amount})
  end

  def withdraw(amount) do
    GenServer.cast(__MODULE__, {:withdraw, amount})
  end

  def get_balance() do
    GenServer.call(__MODULE__, :balance)
  end

  ### GenServer's Kitchen

  # ...the code we wrote before...
end
```

> [!note]
>
> Here is how we can use it with this nice API:
>
> ```console
> iex> Kingdom.Treasury.open()
> {:ok, #PID<0.159.0>}
> iex> Kingdom.Treasury.store(100)
> :ok
> iex> Kingdom.Treasury.store(500)
> :ok
> iex> Kingdom.Treasury.withdraw(300)
> :ok
> iex> Kingdom.Treasury.get_balance()
> 300
> ```

### Simulate Crashes for Treasury

We can simulate process crashes by adding an API call and the its handler that will raise some exception:

```elixir
# ...

def crash() do
  GenServer.call(__MODULE__, :apocalypse)
end

# ...

def handle_call(:apocalypse, _from, _balance) do
  raise "Oops"
end

# ...
```

> [!note]
>
> How this looks in action:
>
> ```console
> iex> Kingdom.Treasury.open()
> {:ok, #PID<0.161.0>}
> iex> Kingdom.Treasury.store(100)
> :ok
> iex> Kingdom.Treasury.get_balance()
> 100
> iex> Kingdom.Treasury.crash
> ** (exit) exited in: GenServer.call(Kingdom.Treasury, :apocalypse, 5000)
>     ** (EXIT) an exception was raised:
>         ** (RuntimeError) Oops
> # ...
> iex> Kingdom.Treasury.get_balance()
> ** (exit) exited in: GenServer.call(Kingdom.Treasury, :balance, 5000)
>     ** (EXIT) no process: the process is not alive or there's no process currently associated with the given name, possibly because its application isn't started
> # ...
> ```

### Supervising the Treasury

Letting a treasury run without supervision is a bit irresponsible, and a good way to lose your funds or your head.

Thankfully, OTP provides us with the [supervisor behaviour](https://hexdocs.pm/elixir/Supervisor.html). Supervisors can:

- start and shutdown applications,
- provide fault tolerance by restarting crashed processes,
- be used to make a hierarchical supervision structure, called a _supervision tree_.

Let’s equip our treasury with a simple supervisor. Create `lib/kingdom/treasury_supervisor.ex`:

```elixir
defmodule Kingdom.TreasurySupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    children = [
      %{
        id: Kingdom.Treasury,
        start: {Kingdom.Treasury, :open, []}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

We also need to add the new supervisor to the main application supervision tree. Open `lib/kingdom/application.ex` and add it to the `children` specification:

```elixir
children = [
  {Kingdom.TreasurySupervisor, []}
]
# ...
```

Now, our Treasury server process starts automatically with the application!

> [!note]
>
> ```console
> iex> Kingdom.Treasury.get_balance()
> 0
> iex> Kingdom.Treasury.store(100)
> :ok
> iex> Kingdom.Treasury.get_balance()
> 100
> ```

> [!important]
>
> The Treasury process even gets automatically restarted after crashes:
>
> ```console
> iex> Kingdom.Treasury.get_balance()
> 0
> iex> Kingdom.Treasury.store(100)
> :ok
> iex> Kingdom.Treasury.get_balance()
> 100
> iex> Kingdom.Treasury.crash()
>
> 18:22:41.486 [error] GenServer Kingdom.Treasury terminating
> ** (RuntimeError) Oops
>     (kingdom 0.1.0) lib/kingdom/treasury.ex:45: Kingdom.Treasury.handle_call/3
>     (stdlib 5.1.1) gen_server.erl:1113: :gen_server.try_handle_call/4
>     (stdlib 5.1.1) gen_server.erl:1142: :gen_server.handle_msg/6
>     (stdlib 5.1.1) proc_lib.erl:241: :proc_lib.init_p_do_apply/3
> Last message (from #PID<0.155.0>): :apocalypse
> State: 100
> Client #PID<0.155.0> is alive
> # ...
> iex> Kingdom.Treasury.get_balance()
> 0
> iex> Kingdom.Treasury.store(1337)
> :ok
> iex> Kingdom.Treasury.get_balance()
> 1337
> ```

...however, even our supervisor restarts the process, it doesn't restore its state before the crash. It's not really a supervisor's job.
