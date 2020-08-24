defmodule Proj3.MainServer do
use GenServer

def start_link(args)do
  message="Started Main Server."
  IO.inspect(message)
  GenServer.start_link(__MODULE__, args, name: __MODULE__)
end

def init({nodes, hops, failure}) do
  Process.send_after(self(), :execute, 0)
  # IO.inspect(nodes)
  # IO.inspect(hops)
  maxCount = ceil(nodes*hops*(100-failure)/100)
  {:ok, {nodes, hops, maxCount, failure} }
end

def handle_info(:execute, {nodes, hops, maxCount, failure}) do
  # y="#{inspect x}"
  nodeList=  for _<- 1..nodes-1 do Proj3.NodeSupervisor.add_node() end
  createHashlist()

  {:noreply, {nodeList, hops, maxCount, failure}}
end

def createHashlist() do
  GenServer.cast(__MODULE__, :createHashlist)
end

def broadcast(pid, serverState, hashValue, hashList, hops, doa) do
  GenServer.cast(pid, {:createRoutingTable, serverState, hashValue, hashList, hops, doa})
end

def broadcast(pid, newNodePid, newNodeHash) do
  GenServer.cast(pid, {:addNewNode, newNodePid, newNodeHash})
end

def finalDestination(hopCounts) do
  GenServer.cast(__MODULE__, {:finalDestination, hopCounts})
end

def findReplacementPid(selfHash, nextPid, level) do
  GenServer.call(__MODULE__, {:findReplacementPid, selfHash, nextPid, level})
end

def tellItsDone(ownPid, doa) do
  GenServer.cast(__MODULE__, {:tellItsDone, ownPid, doa})
end

def checkIfReady(checkPid) do
  GenServer.call(__MODULE__, {:checkIfReady, checkPid})
end

def handle_call({:checkIfReady, checkPid}, _from, {state, hashList, currentCount, maxCount, maxHop, readyNodes}) do
  status=if Map.has_key?(readyNodes, checkPid) do readyNodes[checkPid] else "notready" end
  {:reply, status ,{state, hashList, currentCount, maxCount, maxHop, readyNodes} }
end

def handle_cast({:tellItsDone, ownPid, doa}, {state, hashList, currentCount, maxCount, maxHop, readyNodes} ) do
  readyNodes=Map.put(readyNodes, ownPid, doa)
  {:noreply, {state, hashList, currentCount, maxCount, maxHop, readyNodes} }
end

def handle_cast(:createHashlist, {nodeList, hops, maxCount, failure}) do

  state=Enum.reduce(nodeList, %{}, fn x , acc -> Map.put(acc, x, :crypto.hash(:sha, "#{inspect x}") |> Base.encode16 ) end)
  hashList=Enum.reduce(nodeList, [], fn x , acc -> acc ++ [:crypto.hash(:sha, "#{inspect x}") |> Base.encode16 ] end)
  # state=Enum.map(nodeList , fn x ->[x, :crypto.hash(:sha, x) |> Base.encode16] end)
  newNodePid=Proj3.NodeSupervisor.add_node()
  newNodeHash=:crypto.hash(:sha, "#{inspect newNodePid}")|> Base.encode16


  dead=ceil(failure*length(nodeList)/100)
  alive=length(nodeList)-dead

  # IO.inspect(dead)
  # IO.inspect(alive)
  # IO.inspect(length(nodeList))

  doa="dead"

  # IO.inspect(Enum.slice(state, 0..dead-1))
  # IO.inspect(Enum.slice(state, dead..length(nodeList)))

  Enum.each( Enum.slice(state, 0..dead-1),  fn {pid, hashValue} ->

    broadcast(pid, state, hashValue, hashList--[hashValue], hops, doa)
   end)

   doa="alive"
   Enum.each( Enum.slice(state, dead..length(nodeList)),  fn {pid, hashValue} ->

    broadcast(pid, state, hashValue, hashList--[hashValue], hops, doa)
    broadcast(pid, newNodePid, newNodeHash)
   end)
   broadcast(newNodePid, Map.merge(state, %{newNodePid => newNodeHash}), newNodeHash, hashList, hops, doa)
   hashList=hashList++[newNodeHash]
  #  IO.inspect(state)
  #  IO.inspect(hashList)
   currentCount=0
   maxHop=0
   readyNodes=%{}
  {:noreply, {state, hashList, currentCount, maxCount, maxHop, readyNodes}}
end

def handle_cast({:finalDestination, hopCounts}, {state, hashList, currentCount, maxCount, maxHop, readyNodes}) do
currentCount=currentCount+1

maxHop= if hopCounts > maxHop do hopCounts else maxHop end
if currentCount==maxCount do

  IO.puts("Total Messages: #{inspect currentCount}")
  IO.puts("MaxHops is #{inspect maxHop}")

  System.halt(0)
end

{:noreply, {state, hashList, currentCount, maxCount, maxHop, readyNodes}}
end


def handle_call({:findReplacementPid, selfHash, nextPid, level}, _from,  {state, hashList, currentCount, maxCount, maxHop, readyNodes}) do

  nextHash=state[nextPid]
  newHashList=hashList--[nextHash]
  newHashList=newHashList--[selfHash]

  replacementHash=Enum.reduce_while(newHashList, [], fn x, acc ->
    if numberofmatchingdigits(selfHash, x, 0)==level and readyNodes[findkey(state,x)]=="alive", do: {:halt, acc ++ [x]}, else: {:cont, acc}
  end)
  replcementPid=findkey(state, Enum.at(replacementHash,0) )
  replacementHash=Enum.at(replacementHash,0)


  {:reply, {replcementPid, String.at(replacementHash,level), String.at(nextHash,level)}, {state, hashList, currentCount, maxCount, maxHop, readyNodes}}
  end

  def findkey(map,l) do
    map |> Enum.find(fn {_key, val} -> val == l end) |> elem(0)
  end


  def numberofmatchingdigits(str1,str2,index) do
    if String.at(str1,index) == String.at(str2,index) and (index < String.length(str1) or index < String.length(str2)) do
      numberofmatchingdigits(str1,str2,index+1)
    else
      index
    end
  end


end


