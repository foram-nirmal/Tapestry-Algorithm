defmodule Proj3.MainServer do
use GenServer

def start_link(args)do
  message="Started Main Server."
  IO.inspect(message)
  GenServer.start_link(__MODULE__, args, name: __MODULE__)
end

def init({nodes, hops}) do
  Process.send_after(self(), :execute, 0)
  # IO.inspect(nodes)
  # IO.inspect(hops)
  maxCount = nodes*hops
  {:ok, {nodes, hops, maxCount} }
end

def handle_info(:execute, {nodes, hops, maxCount}) do
  # y="#{inspect x}"
  nodeList=  for _<- 1..nodes-1 do Proj3.NodeSupervisor.add_node() end
  createHashlist()

  {:noreply, {nodeList, hops, maxCount}}
end

def createHashlist() do
  GenServer.cast(__MODULE__, :createHashlist)
end

def broadcast(pid, serverState, hashValue, hashList, hops) do
  GenServer.cast(pid, {:createRoutingTable, serverState, hashValue, hashList, hops})
end

def broadcast(pid, newNodePid, newNodeHash) do
  GenServer.cast(pid, {:addNewNode, newNodePid, newNodeHash})
end

def finalDestination(hopCounts) do
  GenServer.cast(__MODULE__, {:finalDestination, hopCounts})
end

def handle_cast(:createHashlist, {nodeList, hops, maxCount}) do

  state=Enum.reduce(nodeList, %{}, fn x , acc -> Map.put(acc, x, :crypto.hash(:sha, "#{inspect x}") |> Base.encode16 ) end)
  hashList=Enum.reduce(nodeList, [], fn x , acc -> acc ++ [:crypto.hash(:sha, "#{inspect x}") |> Base.encode16 ] end)
  # state=Enum.map(nodeList , fn x ->[x, :crypto.hash(:sha, x) |> Base.encode16] end)
  newNodePid=Proj3.NodeSupervisor.add_node()
  newNodeHash=:crypto.hash(:sha, "#{inspect newNodePid}")|> Base.encode16

  Enum.each( state,  fn {pid, hashValue} ->
    broadcast(pid, state, hashValue, hashList--[hashValue], hops)
    broadcast(pid, newNodePid, newNodeHash)
   end)

   broadcast(newNodePid, Map.merge(state, %{newNodePid => newNodeHash}), newNodeHash, hashList, hops)
   hashList=hashList++[newNodeHash]
  #  IO.inspect(state)
  #  IO.inspect(hashList)
   currentCount=0
   maxHop=0
  {:noreply, {state, hashList, currentCount, maxCount, maxHop}}
end

def handle_cast({:finalDestination, hopCounts}, {state, hashList, currentCount, maxCount, maxHop}) do

currentCount=currentCount+1

maxHop= if hopCounts > maxHop do hopCounts else maxHop end
if currentCount==maxCount do

  IO.puts("Total Messages: #{inspect currentCount}")
  IO.puts("MaxHops is #{inspect maxHop}")

  System.halt(0)
end

{:noreply, {state, hashList, currentCount, maxCount, maxHop}}
end






end
