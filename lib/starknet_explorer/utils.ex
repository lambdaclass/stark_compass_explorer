defmodule StarknetExplorer.Utils do
  defmacro if_prod(do: tBlock, else: fBlock) do
    case Mix.env() do
      # If this is a prod block
      :prod ->
        quote do
          unquote(tBlock)
        end

      # otherwise go with the alternative
      _ ->
        if nil != fBlock do
          quote do
            unquote(fBlock)
          end
        end
    end
  end

  def last_n_characters(input_string, n) do
    # Calculate the starting index
    start_index = String.length(input_string) - n

    # Keep the last N characters
    String.slice(input_string, start_index..-1)
  end

  def format_number_for_display(n) when is_number(n) do
    n
    |> to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.reverse(&1))
    |> Enum.reverse()
    |> Enum.join(",")
  end

  @spec listener_atom(any) :: atom
  def listener_atom(network) do
    String.to_atom("listener_#{network}")
  end

  def trim_leading_zeroes(address) do
    String.replace(address, ~r/(0x)0+/, "\\1")
  end
end
