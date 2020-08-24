defmodule Neighbor_table do
  def neighbors(mainnode) do
    # for i <- 0..10 do
    #   spawn fn -> list ++ :crypto.hash(:sha, i) end
    # end
    neighbors_list = List.duplicate([],40)
    intermap = %{}
    mainmap = %{}
    map = %{}
    nodes = for i <- 1..10 do
      pid = Kernel.inspect(spawn fn -> 1 + 2 end)
      sha = :crypto.hash(:sha, pid) |> Base.encode16
    end
    map = for i <- 0..15 do
      Map.put(map, i, Integer.to_string(i,16))
    end
    mainmap = for i <- 0..length(nodes)-1 do
      matches = numberofmatchingdigits(mainnode,Enum.at(nodes,i),0)
      if Map.has_key?(mainmap,matches) do
        if Map.has_key?(Map.fetch!(mainmap,matches),String.at(Enum.at(nodes,i),0)) do
          distance = elem(Integer.parse(Map.fetch!(mainmap,matches),16),0) - elem(Integer.parse(Enum.at(nodes,i)),0)
          if distance < 0 do
            mainmap = Map.replace!(mainmap, matches , Map.put(intermap,String.at(Enum.at(nodes,i),0),Enum.at(nodes,i)))
          end
        end
      else
          mainmap = Map.put(mainmap, matches , Map.put(intermap,String.at(Enum.at(nodes,i),0),Enum.at(nodes,i)))
      end
    end
  end
  def numberofmatchingdigits(str1,str2,index) do
    if String.at(str1,index) == String.at(str2,index) and (index < String.length(str1) or index < String.length(str2)) do
      numberofmatchingdigits(str1,str2,index+1)
    else
      index
    end
  end
end
