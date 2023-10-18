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
