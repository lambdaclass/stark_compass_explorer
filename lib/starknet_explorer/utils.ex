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
end
