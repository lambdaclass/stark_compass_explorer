defmodule StarknetExplorer.S3 do
  def list_buckets() do
    ExAws.S3.list_buckets()
    |> ExAws.request!()
    |> get_in([:body, :buckets])
  end

  def upload_object!(binary_element, path) do
    bucket_name = Application.get_env(:starknet_explorer, :s3_bucket_name)

    ExAws.S3.put_object(bucket_name, path, binary_element)
    |> ExAws.request!()

    :ok
  end

  def list_objects do
    bucket_name = Application.get_env(:starknet_explorer, :s3_bucket_name)

    ExAws.S3.list_objects(bucket_name)
    |> ExAws.request!()
    |> get_in([:body, :contents])
  end

  def list_objects(path) do
    bucket_name = Application.get_env(:starknet_explorer, :s3_bucket_name)

    ExAws.S3.list_objects(bucket_name, prefix: path)
    |> ExAws.request!()
    |> get_in([:body, :contents])
  end

  def get_object!(key) do
    bucket_name = Application.get_env(:starknet_explorer, :s3_bucket_name)

    ExAws.S3.get_object(bucket_name, key)
    |> ExAws.request!()
  end

  def delete_object!(key) do
    bucket_name = Application.get_env(:starknet_explorer, :s3_bucket_name)

    ExAws.S3.delete_object(bucket_name, key)
    |> ExAws.request!()
  end

  def download_object!(key, filename) do
    bucket_name = Application.get_env(:starknet_explorer, :s3_bucket_name)

    :done =
      ExAws.S3.download_file(bucket_name, key, filename)
      |> ExAws.request!()

    :ok
  end
end
