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
