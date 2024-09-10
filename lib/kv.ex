defmodule KV do
  defstruct store: %{}, in_transaction: false,transaction_logs: [[]]
  def begin_transaction(%KV{in_transaction: false} = kv_store) do
    updated_kv_store = %{kv_store | in_transaction: true}
    {updated_kv_store, "BEGIN\n1"}
  end

  def begin_transaction(%KV{in_transaction: true} = kv_store) do
    new_logs = [[] | kv_store.transaction_logs]
    {updated_kv_store, count} = { %{kv_store | transaction_logs: new_logs}, length(new_logs)}
    {updated_kv_store, "BEGIN\n#{count}"}
  end

  def commit(%KV{in_transaction: true, transaction_logs: [current_log]} = kv_store) do
    new_store = apply_transaction_logs(current_log, kv_store.store)
    {%{kv_store | store: new_store, transaction_logs: [[]], in_transaction: false}, "COMMIT\n0"}
  end

  def commit(%KV{in_transaction: true, transaction_logs: [current_log | rest_logs]} = kv_store) do
    [next_log | older_logs] = rest_logs
    merged_log = current_log ++ next_log
    new_depth = length(rest_logs)

    {%{kv_store | transaction_logs: [merged_log | older_logs]}, "COMMIT\n#{new_depth}"}
  end

  def rollback(%KV{in_transaction: true, transaction_logs: [_log]} = kv_store) do
    updated_kv_store = %{kv_store | transaction_logs: [[]], in_transaction: false}
    {updated_kv_store, "ROLLBACK\n0"}
  end

  def rollback(%KV{in_transaction: true, transaction_logs: [_log | rest]} = kv_store) do
    updated_kv_store = %{kv_store | transaction_logs: rest}
    {updated_kv_store, "ROLLBACK\n#{length(rest)}"}
  end

  def set(%KV{in_transaction: true, transaction_logs: logs} = kv_store, key, value) do
    new_log = [{:set, key, value} | hd(logs)]
    new_logs = [new_log | tl(logs)]
    {_, message} = handle_set(kv_store.store, key, value)
    {%{kv_store | transaction_logs: new_logs}, message}
  end

 def set(%KV{in_transaction: false} = kv_store, key, value) do
    {updated_store, message} = handle_set(kv_store.store, key, value)
    {%{kv_store | store: updated_store}, message}
  end

  defp handle_set(store, key, value) do
    case Map.get(store, key) do
      nil ->
        {Map.put(store, key, value), "FALSE #{value}"}
      _ ->
        {Map.put(store, key, value), "TRUE #{value}"}
    end
  end

  def get(%KV{in_transaction: true, transaction_logs: logs} = kv_store, key) do
    case Enum.find_value(logs, fn log ->
      case Enum.find(log, fn {op, k, _v} -> op == :set and k == key end) do
        {:set, _key, value} -> value
        _ -> nil
      end
    end) do
      nil -> Map.get(kv_store.store, key)
      value -> value
    end
  end
  def get(%KV{store: store}, key) do
    Map.get(store, key)
  end

defp apply_transaction_logs(log, store) do
    Enum.reduce(log, store, fn
      {:set, key, value}, acc -> Map.put(acc, key, value)
      {:delete, key}, acc -> Map.delete(acc, key)
    end)
  end
end
