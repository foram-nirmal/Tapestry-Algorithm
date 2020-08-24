defmodule Proj3.Node do
  use GenServer

  def start_link(_) do

    GenServer.start_link(__MODULE__, :no_args)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_cast({:addNewNode, newNodePid, newNodeHash}, {ownHash , routingTable}) do
    sourcenode=ownHash
    mainmap=routingTable
    x=newNodeHash
    matches = numberofmatchingdigits(sourcenode,newNodeHash,0)

    if Map.has_key?(mainmap,matches) do
      if Map.has_key?(Map.fetch!(mainmap,matches),x) do
        distanceOriginal= abs( elem(Integer.parse(mainmap[matches],16),0) - elem(Integer.parse(sourcenode,16),0) )
        distanceNew = abs( elem(Integer.parse(x,16),0) - elem(Integer.parse(sourcenode,16),0))

        if distanceNew < distanceOriginal do
          if mainmap[matches]==nil do
            Map.put(mainmap, matches ,   Map.merge(%{},Map.put(%{},String.at(x,matches),newNodePid)) )
          else
            Map.put(mainmap, matches ,   Map.merge(mainmap[matches],Map.put(%{},String.at(x,matches),newNodePid)) )
          end

          end
        end
      else
        if mainmap[matches]==nil do
          Map.put(mainmap, matches ,   Map.merge(%{},Map.put(%{},String.at(x,matches),newNodePid)) )
        else
          Map.put(mainmap, matches ,   Map.merge(mainmap[matches],Map.put(%{},String.at(x,matches),newNodePid)) )
        end        end

    {:noreply, {ownHash ,routingTable}}

  end


  def handle_cast({:createRoutingTable, serverState, hashValue, hashList, hops}, _state) do
    mainnode=hashValue
    nodes=hashList
    mainmap = %{}
    mainmap=Enum.reduce(nodes, %{}, fn x , acc ->

      matches = numberofmatchingdigits(mainnode,x,0)
      if Map.has_key?(mainmap,matches) do
        if Map.has_key?(Map.fetch!(mainmap,matches),x) do
          distanceOriginal= abs( elem(Integer.parse(mainmap[matches],16),0) - elem(Integer.parse(mainnode,16),0) )
          distanceNew = abs( elem(Integer.parse(x,16),0) - elem(Integer.parse(mainnode,16),0))

          if distanceNew < distanceOriginal do
            if acc[matches]==nil do
              Map.put(acc, matches ,   Map.merge(%{},Map.put(%{},String.at(x,matches),findkey(serverState,x))) )
            else
              Map.put(acc, matches ,   Map.merge(acc[matches],Map.put(%{},String.at(x,matches),findkey(serverState,x))) )
            end

            end
          end
        else
          if acc[matches]==nil do
            Map.put(acc, matches ,   Map.merge(%{},Map.put(%{},String.at(x,matches),findkey(serverState,x))) )
          else
            Map.put(acc, matches ,   Map.merge(acc[matches],Map.put(%{},String.at(x,matches),findkey(serverState,x))) )
          end        end
         end)




  #IO.puts("Routing table for #{inspect hashValue} \n #{inspect mainmap} \n\n")
  randomNodes= for _<- 1..hops do  Enum.random(serverState) end
        #  IO.inspect(elem(Enum.at(randomNodes, hops-1),1))

  # randomNode=Enum.random(serverState)

        #sendPacketRandomNodes(findkey(serverState,mainnode),randomNodes, hops)
        Process.send_after(findkey(serverState,mainnode), {:sendPacketRandomNodes, findkey(serverState,mainnode),randomNodes, hops}, 10)
  # sendPacket(findkey(serverState,mainnode), elem(randomNode,0), elem(randomNode,1), -1)
    {:noreply, {hashValue ,mainmap}}
  end

  def handle_info({:sendPacketRandomNodes, ownPID,randomNodes, hops}, state) do
    Process.send_after(ownPID, {:send, ownPID, randomNodes, hops}, 10)
    {:noreply, state}
  end

  def handle_info( {:send , ownPid, randomNodes, hops} , state) do
    if hops>0 do
      finalNodePid=Enum.at(randomNodes, hops-1)
      finalNodeHash=Enum.at(randomNodes, hops-1)

      sendPacket(ownPid, elem(finalNodePid,0), elem(finalNodeHash,1), -1)
      #IO.puts("sent packet #{inspect hops}")
      Process.send_after(ownPid, {:sendPacketRandomNodes, ownPid, randomNodes, hops-1}, 0)
    end

    {:noreply, state}
  end

  # def sendPacketRandomNodes(ownPid,randomNodes, hops) do
  #   # IO.puts("packet sent to #{inspect nextPid}, final node is #{inspect nextPid}")
  #   if hops>0 do
  #     finalNodePid=Enum.at(randomNodes, hops-1)
  #     finalNodeHash=Enum.at(randomNodes, hops-1)

  #     sendPacket(ownPid, elem(finalNodePid,0), elem(finalNodeHash,1), -1)
  #     #IO.puts("sent packet #{inspect hops}")
  #     sendPacketRandomNodes(ownPid,randomNodes, hops-1)
  #   end

  # end

  def sendPacket(nextPid, finalNodePid, finalNodeHash, hopCount) do
    # IO.puts("packet sent to #{inspect nextPid}, final node is #{inspect nextPid}")
    GenServer.cast(nextPid, {:sendPacket, finalNodePid, finalNodeHash, hopCount} )
  end


  def handle_cast({:sendPacket, finalNodePid, finalNodeHash, hopCount}, {selfHash, routingTable}) do
    hopCount=hopCount+1

    if finalNodeHash==selfHash do
      Proj3.MainServer.finalDestination(hopCount)
    else
      matches=numberofmatchingdigits(finalNodeHash, selfHash,0)
      nextPid=routingTable[matches][String.at(finalNodeHash,matches)]

      sendPacket(nextPid,finalNodePid, finalNodeHash, hopCount)
    end

    {:noreply, {selfHash ,routingTable}}
  end






  def numberofmatchingdigits(str1,str2,index) do
    if String.at(str1,index) == String.at(str2,index) and (index < String.length(str1) or index < String.length(str2)) do
      numberofmatchingdigits(str1,str2,index+1)
    else
      index
    end
  end

  def findkey(map,l) do
    map |> Enum.find(fn {_key, val} -> val == l end) |> elem(0)
  end

end
