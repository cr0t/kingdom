defmodule Kingdom.Treasury do
  use GenServer

  def init(balance) do
    {:ok, balance}
  end
end
