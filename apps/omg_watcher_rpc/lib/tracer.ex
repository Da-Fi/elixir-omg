# Copyright 2019-2020 OmiseGO Pte Ltd
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

defmodule OMG.WatcherRPC.Tracer do
  @moduledoc """
  Trace Phoenix requests and reports information to Datadog via Spandex
  """

  use Spandex.Tracer, otp_app: :omg_watcher_rpc
  alias OMG.WatcherRPC.Application

  def add_trace_metadata(%{assigns: %{error_type: error_type, error_msg: error_msg}} = conn) do
    service_name = Application.service_name()
    version = Application.version()

    conn
    |> SpandexPhoenix.default_metadata()
    |> Keyword.put(:service, service_name)
    |> Keyword.put(:error, [{:error, true}])
    |> Keyword.put(:tags, [{:version, version}, {:"error.type", error_type}, {:"error.msg", error_msg}])
  end

  def add_trace_metadata(conn) do
    service_name = Application.service_name()
    version = Application.version()

    conn
    |> SpandexPhoenix.default_metadata()
    |> Keyword.put(:service, service_name)
    |> Keyword.put(:tags, [{:version, version}])
  end
end
