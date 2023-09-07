defmodule Abi do
  @doc "Pads binary data to 32 bytes."
  def pad_to_32_bytes(bin) when is_binary(bin) do
    padding_length = 32 - byte_size(bin)
    padding = <<0::size(padding_length)-unit(8)>>
    <<padding::binary, bin::binary>>
  end

  @doc "Encodes and pads a hex value to a 32-byte binary"
  def encode_hex(address) when is_binary(address) do
    clean_address = address |> String.replace_prefix("0x", "")

    clean_address =
      case rem(String.length(clean_address), 2) do
        1 -> "0" <> clean_address
        _ -> clean_address
      end

    bin = clean_address |> String.replace_prefix("0x", "") |> Base.decode16!(case: :mixed)
    pad_to_32_bytes(bin)
  end

  def encode_packed_mixed([]), do: ""

  def encode_packed_mixed([head | tail]) do
    encoded_head =
      case head do
        number when is_integer(number) -> <<number::unsigned-big-integer-size(256)>>
        hex when is_binary(hex) -> encode_hex(hex)
        array when is_list(array) -> Enum.map(array, &encode_packed_mixed([&1])) |> Enum.join()
        _ -> raise "Unsupported type"
      end

    <<encoded_head::binary, encode_packed_mixed(tail)::binary>>
  end
end
