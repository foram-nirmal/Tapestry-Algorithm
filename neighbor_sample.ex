defmodule Sample do
  def neighbort do
    map = %{}
    nodes = ["1234", "1235", "5694", "5485", "8956", "F5CD", "FF25", "FD66", "FD03", "FFFF", "FD68", "F5CF", "FD67"]
    mainnode = "FD6C"
    intermap = %{}
    mainmap = %{}
    # map = for i <- 0..15 do
    #   Map.put(map, i, Integer.to_string(i,16))
    # end
    # mainmap = for i <- 0..length(nodes)-1 do
    #   matches = numberofmatchingdigits(mainnode,Enum.at(nodes,i),0)
    #   # if Map.has_key?(mainmap, matches) == false do
    #     # mainmap = Map.update(mainmap,matches,[Enum.at(nodes,i)], fn x-> (Map.get(mainmap,matches) ++ [Enum.at(nodes,i)]) end)
    #     if Map.has_key?(mainmap,matches) do
    #       if Map.has_key?(Map.fetch!(mainmap,matches),String.at(Enum.at(nodes,i),0)) do
    #         distance = elem(Integer.parse(Map.fetch!(mainmap,matches),16),0) - elem(Integer.parse(Enum.at(nodes,i)),0)
    #         if distance < 0 do
    #           mainmap = Map.put(mainmap, matches , Map.put(intermap,String.at(Enum.at(nodes,i),0),Enum.at(nodes,i)))
    #         end
    #       end
    #     else
    #         mainmap = Map.put(mainmap, matches , Map.put(intermap,String.at(Enum.at(nodes,i),0),Enum.at(nodes,i)))
    #     end



    #     # %{mainmap | matches =>  [Enum.at(nodes,i)]}
    #   # else
    #   #   Map.put(mainmap, matches , Map.get(mainmap,matches) ++ [Enum.at(nodes,i)])
    #     # %{mainmap | matches => Map.get(mainmap,matches) ++ [Enum.at(nodes,i)]}
    #   # end
    # end

# emptymap=Enum.reduce(0..nodes-1, %{}, fn x , acc -> Map.put(acc, x , %{}) end)

    mainmap=Enum.reduce(nodes, %{}, fn x , acc ->

      matches = numberofmatchingdigits(mainnode,x,0)
      if Map.has_key?(mainmap,matches) do
        if Map.has_key?(Map.fetch!(mainmap,matches),x) do
          distanceOriginal= abs( elem(Integer.parse(mainmap[matches],16),0) - elem(Integer.parse(mainnode,16),0) )
          distanceNew = abs( elem(Integer.parse(x,16),0) - elem(Integer.parse(mainnode,16),0))

          if distanceNew < distanceOriginal do
            if acc[matches]==nil do
              Map.put(acc, matches ,   Map.merge(%{},Map.put(%{},String.at(x,matches),x)) )
            else
              Map.put(acc, matches ,   Map.merge(acc[matches],Map.put(%{},String.at(x,matches),x)) )
            end

            end
          end
        else
          if acc[matches]==nil do
            Map.put(acc, matches ,   Map.merge(%{},Map.put(%{},String.at(x,matches),x)) )
          else
            Map.put(acc, matches ,   Map.merge(acc[matches],Map.put(%{},String.at(x,matches),x)) )
          end        end
         end)
    # IO.inspect(mainmap)

    # x = Map.merge(Enum.at(mainmap,0),Enum.at(mainmap,1),fn v1,v2-> [v1,v2] end)

    # Enum.flat_map(mainmap,fn x -> [x] end)
    # IO.inspect(mainmap)
  end
  def numberofmatchingdigits(str1,str2,index) do
    if String.at(str1,index) == String.at(str2,index) and (index < String.length(str1) or index < String.length(str2)) do
      numberofmatchingdigits(str1,str2,index+1)
    else
      index
    end
  end
end
