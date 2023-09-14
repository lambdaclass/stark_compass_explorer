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
end
