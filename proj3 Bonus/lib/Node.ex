defmodule Proj3.Node do
  use GenServer

  def start_link(_) do

    GenServer.start_link(__MODULE__, :no_args)
  end

  def init(_) do
    {:ok, []}
  end

  def handle_cast({:addNewNode, newNodePid, newNodeHash}, {ownHash , routingTable, doa}) do
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

    {:noreply, {ownHash ,routingTable, doa}}

  end

  def handle_cast({:createRoutingTable, serverState, hashValue, hashList, hops, doa}, _state) do
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



  #IO.puts("Routing table for #{inspect hashValue} \n #{inspect mainmap} \n #{inspect findkey(serverState,mainnode)} \n\n")
  randomNodes= for _<- 1..hops do  Enum.random(serverState) end
        #  IO.inspect(elem(Enum.at(randomNodes, hops-1),1))

  # randomNode=Enum.random(serverState)

        #sendPacketRandomNodes(findkey(serverState,mainnode),randomNodes, hops)

        Process.send_after(findkey(serverState,mainnode), {:sendPacketRandomNodes, findkey(serverState,mainnode),randomNodes, hops}, 10)
  # sendPacket(findkey(serverState,mainnode), elem(randomNode,0), elem(randomNode,1), -1)

    # tell main server reouting tablke done -- ownPid
    Proj3.MainServer.tellItsDone(findkey(serverState,mainnode), doa)

    {:noreply, {hashValue , mainmap, doa}}
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
      Process.send_after(ownPid, {:sendPacketRandomNodes, ownPid, randomNodes, hops-1}, 10)
    end

    {:noreply, state}
  end


  def handle_info({:delaySend, nextPid,finalNodePid,finalNodeHash, hopCount}, state) do
    GenServer.cast(nextPid, {:sendPacket, finalNodePid, finalNodeHash, hopCount} )
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


  def handle_cast({:sendPacket, finalNodePid, finalNodeHash, hopCount}, {selfHash, routingTable, doa}) do
    hopCount=hopCount+1

    if finalNodeHash==selfHash do
      Proj3.MainServer.finalDestination(hopCount)
    else
      matches=numberofmatchingdigits(finalNodeHash, selfHash,0)

      nextPid=routingTable[matches][String.at(finalNodeHash,matches)]

      status= Proj3.MainServer.checkIfReady(nextPid)
    # IO.puts("initial RT #{inspect routingTable} for #{inspect selfHash}")
     routingTable=
      cond do
        status=="dead" && nextPid==finalNodePid -> Proj3.MainServer.finalDestination(hopCount)
        routingTable
        status=="dead" -> level=numberofmatchingdigits(selfHash,routingTable[nextPid],0)
                          replacementPid=Proj3.MainServer.findReplacementPid(selfHash , nextPid, level)
                        #  IO.puts("reaplacemtne id dead node#{inspect nextPid} #{inspect replacementPid} for #{inspect selfHash} finak node #{inspect finalNodePid}")
                          temp=Map.put(Map.delete(routingTable[level], elem(replacementPid,2)) , elem(replacementPid,1), elem(replacementPid,0))

                          routingTable=Map.put(routingTable, level, temp)
                          Process.send_after(self(),{:delaySend, nextPid,finalNodePid,finalNodeHash, hopCount}, 100 )
                          #sendPacket(elem(replacementPid,0),finalNodePid, finalNodeHash, hopCount)
                          routingTable

       # status=="notready"-> sendPacket(self(),finalNodePid, finalNodeHash, hopCount)
        status=="alive" -> sendPacket(nextPid,finalNodePid, finalNodeHash, hopCount)
        routingTable
        true -> 0
        routingTable
      end
     # IO.puts("post RT #{inspect routingTable} for #{inspect selfHash}")

    #  IO.puts("#{inspect status}")
     end

    {:noreply, {selfHash ,routingTable, doa}}
  end



  def handle_call(:check, _from, {hashValue , routingTable, doa}) do
    reply= if doa=="alive"  do
                              "yes"
                            else
                              "no"
                            end
    {:reply,reply ,{hashValue ,routingTable, doa}}
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
