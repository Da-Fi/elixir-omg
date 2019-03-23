# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule OMG.TestHelper do
  @moduledoc false

  alias OMG.Crypto
  alias OMG.DevCrypto
  alias OMG.State.Core
  alias OMG.State.Transaction

  @type entity :: %{priv: Crypto.priv_key_t(), addr: Crypto.pub_key_t()}

  # Deterministic entities. Use only when truly needed.
  def entities_stable,
    do: %{
      stable_alice: %{
        priv:
          <<54, 43, 207, 67, 140, 160, 190, 135, 18, 162, 70, 120, 36, 245, 106, 165, 5, 101, 183, 55, 11, 117, 126,
            135, 49, 50, 12, 228, 173, 219, 183, 175>>,
        addr: <<59, 159, 76, 29, 210, 110, 11, 229, 147, 55, 59, 29, 54, 206, 226, 0, 140, 190, 184, 55>>
      },
      stable_bob: %{
        priv:
          <<208, 253, 134, 150, 198, 155, 175, 125, 158, 156, 21, 108, 208, 7, 103, 242, 9, 139, 26, 140, 118, 50, 144,
            21, 226, 19, 156, 2, 210, 97, 84, 128>>,
        addr: <<207, 194, 79, 222, 88, 128, 171, 217, 153, 41, 195, 239, 138, 178, 227, 16, 72, 173, 118, 35>>
      },
      stable_mallory: %{
        priv:
          <<89, 253, 200, 245, 173, 195, 234, 62, 168, 206, 213, 19, 136, 51, 147, 209, 1, 14, 180, 107, 106, 8, 133,
            131, 75, 157, 81, 109, 102, 19, 91, 130>>,
        addr: <<48, 120, 88, 246, 235, 202, 79, 121, 216, 73, 40, 199, 165, 186, 120, 113, 36, 119, 87, 207>>
      }
    }

  def entities,
    do:
      Map.merge(
        %{
          alice: generate_entity(),
          bob: generate_entity(),
          carol: generate_entity()
        },
        entities_stable()
      )

  @spec generate_entity :: entity()
  def generate_entity do
    {:ok, priv} = DevCrypto.generate_private_key()
    {:ok, pub} = DevCrypto.generate_public_key(priv)
    {:ok, addr} = Crypto.generate_address(pub)
    %{priv: priv, addr: addr}
  end

  def do_deposit(state, owner, %{amount: amount, currency: cur, blknum: blknum}) do
    {:ok, {_, _}, new_state} =
      Core.deposit([%{owner: owner.addr, currency: cur, amount: amount, blknum: blknum}], state)

    new_state
  end

  @doc """
  convenience function around Transaction.new to create recovered transactions,
  by allowing to provider private keys of utxo owners along with the inputs
  """
  @spec create_recovered(
          list({pos_integer, pos_integer, 0 | 1, map}),
          Transaction.currency(),
          list({Crypto.address_t(), pos_integer}),
          Transaction.metadata()
        ) :: Transaction.Recovered.t()
  def create_recovered(inputs, currency, outputs, metadata \\ nil) do
    create_encoded(inputs, currency, outputs, metadata) |> Transaction.Recovered.recover_from!()
  end

  @spec create_recovered(
          list({pos_integer, pos_integer, 0 | 1, map}),
          list({Crypto.address_t(), Transaction.currency(), pos_integer})
        ) :: Transaction.Recovered.t()
  def create_recovered(inputs, outputs), do: create_encoded(inputs, outputs) |> Transaction.Recovered.recover_from!()

  def create_encoded(inputs, currency, outputs, metadata \\ nil) do
    create_signed(inputs, currency, outputs, metadata) |> Transaction.Signed.encode()
  end

  def create_encoded(inputs, outputs) do
    create_signed(inputs, outputs) |> Transaction.Signed.encode()
  end

  @doc """
  convenience function around Transaction.new to create signed transactions (see create_recovered)
  """
  @spec create_signed(
          list({pos_integer, pos_integer, 0 | 1, map}),
          Transaction.currency(),
          list({Crypto.address_t(), pos_integer}),
          Transaction.metadata()
        ) :: Transaction.Signed.t()
  def create_signed(inputs, currency, outputs, metadata \\ nil) do
    raw_tx =
      Transaction.new(
        inputs |> Enum.map(fn {blknum, txindex, oindex, _} -> {blknum, txindex, oindex} end),
        outputs |> Enum.map(fn {owner, amount} -> {owner.addr, currency, amount} end),
        metadata
      )

    privs = get_private_keys(inputs)
    DevCrypto.sign(raw_tx, privs)
  end

  @spec create_signed(
          list({pos_integer, pos_integer, 0 | 1, map}),
          list({Crypto.address_t(), Transaction.currency(), pos_integer})
        ) :: Transaction.Signed.t()
  def create_signed(inputs, outputs) do
    raw_tx =
      Transaction.new(
        inputs |> Enum.map(fn {blknum, txindex, oindex, _} -> {blknum, txindex, oindex} end),
        outputs |> Enum.map(fn {owner, currency, amount} -> {owner.addr, currency, amount} end)
      )

    privs = get_private_keys(inputs)
    DevCrypto.sign(raw_tx, privs)
  end

  defp get_private_keys(inputs) do
    filler = List.duplicate(<<>>, 4 - length(inputs))

    inputs
    |> Enum.map(fn {_, _, _, owner} -> owner.priv end)
    |> Enum.concat(filler)
  end

  @spec write_fee_file(%{Crypto.address_t() => non_neg_integer}) :: {:ok, binary}
  def write_fee_file(map) do
    {:ok, json} =
      map
      |> Enum.map(fn {"0x" <> _ = k, v} -> %{token: k, flat_fee: v} end)
      |> Poison.encode()

    {:ok, path} = Briefly.create(prefix: "omisego_operator_test_fees_file")
    :ok = File.write(path, json, [:write])
    {:ok, path}
  end
end