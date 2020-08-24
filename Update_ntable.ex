defmodule Update do
  def update_neighbort(newnode) do
    map = %{
      0 => %{"1" => "1235", "5" => "5485", "8" => "8956"},
      1 => %{"5" => "F5CF", "F" => "FFFF"},
      2 => %{"0" => "FD03"},
      3 => %{"6" => "FD66", "7" => "FD67", "8" => "FD68"}
    }

    sourcenode = "FD6C"
    matches = numberofmatchingdigits(sourcenode,newnode,0)
    if Map.has_key?(Map.fetch!(map,matches),String.at(newnode,matches))  do
      distanceoriginal = abs(elem(Integer.parse(Map.fetch!(Map.fetch!(map,matches),String.at(newnode,matches)),16),0) - elem(Integer.parse(sourcenode,16),0))
      distancenew = abs(elem(Integer.parse(newnode,16),0) - elem(Integer.parse(sourcenode,16),0))
      # IO.inspect(distanceoriginal)
      # IO.inspect(distancenew)
      if distancenew < distanceoriginal do
      #  map =  Map.update(map,matches,Map.fetch!(Map.fetch!(map,matches),String.at(newnode,matches)),fn x -> Map.put(Map.fetch!(map,matches),String.at(newnode,matches),newnode) end)
      #  Map.put(map,matches,Map.fetch!(Map.fetch!(map,matches),String.at(newnode,matches))
        Map.put(Map.fetch!(map,matches),String.at(newnode,matches),newnode)
        IO.inspect(map)
      end
    else
      # map =  Map.update(map,matches,Map.fetch!(Map.fetch!(map,matches),String.at(newnode,matches)),fn x -> Map.put(Map.fetch!(map,matches),String.at(newnode,matches),newnode) end)
        Map.put(Map.fetch!(map,matches),String.at(newnode,matches),newnode)
        IO.inspect(map)
    end
    IO.inspect(map)
    # if(Map.fetch!(map,matches) == Map.values(m) |> Enum.member?(v)
  end
  def numberofmatchingdigits(str1,str2,index) do
    if String.at(str1,index) == String.at(str2,index) and (index < String.length(str1) or index < String.length(str2)) do
      numberofmatchingdigits(str1,str2,index+1)
    else
      index
    end
  end
end
