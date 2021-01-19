# Copyright 2019-2020 OMG Network Pte Ltd
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

<<<<<<< HEAD:apps/omg_utils/test/omg_utils/app_version_tet.exs
defmodule OMG.Utils.AppVersionTest do
  use ExUnit.Case, async: true

  alias OMG.Utils.AppVersion

  describe "version/1" do
    test "returns a compliant semver when given an application" do
      # Using :elixir as the app because it is certain to be running during the test
      version = AppVersion.version(:elixir)
      assert {:ok, _} = Version.parse(version)
    end
=======
defmodule LoadTest.Scenario.StartStandardExit do
  @moduledoc """
  Starts a standard exit.

  ## configuration values
  - `exiter` the account that's starting the exit
  - `utxo` the utxo to exit
  """

  use Chaperon.Scenario

  alias Chaperon.Session
  alias LoadTest.ChildChain.Exit

  def run(session) do
    exiter = config(session, [:exiter])
    utxo = config(session, [:utxo])
    gas_price = config(session, [:gas_price])

    tx_hash =
      utxo
      |> Exit.wait_for_exit_data()
      |> Exit.start_exit(exiter, gas_price)

    Session.assign(session, tx_hash: tx_hash)
>>>>>>> origin/master:priv/perf/apps/load_test/lib/scenario/start_standard_exit.ex
  end
end
