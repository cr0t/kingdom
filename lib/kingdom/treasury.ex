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

  def crash() do
    GenServer.call(__MODULE__, :apocalypse)
  end

  ### GenServer's Kitchen

  def init(balance) do
    {:ok, balance}
  end

  def handle_cast({:store, amount}, balance) do
    {:noreply, balance + amount}
  end

  def handle_cast({:withdraw, amount}, balance) do
    {:noreply, balance - amount}
  end

  def handle_call(:balance, _from, balance) do
    {:reply, balance, balance}
  end

  def handle_call(:apocalypse, _from, _balance) do
    raise "Oops"
  end
end
