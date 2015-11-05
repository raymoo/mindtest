-- if the node is loaded, returns it. If it isn't loaded, load it and return nil.
-- (lifted from technic mod)
function mindtest.get_or_load_node(pos)
   local node_or_nil = minetest.get_node_or_nil(pos)
   if node_or_nil then return node_or_nil end
   local vm = VoxelManip()
   local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
   return nil
end


-- If a node is unloaded, try to load and then get with minetest.get_node
function mindtest.get_and_load_node(pos)
   return mindtest.get_or_load_node(pos) or mindtest.get_node(pos)
end


function mindtest.get_meta_table(metaRef, tableName)

   local tableString = metaRef:get_string(tableName)

   if tableString then
      return minetest.deserialize(tableString)
   else
      return nil
   end
end


function mindtest.set_meta_table(metaRef, tableName, tabl)
   metaRef:set_string(tableName, minetest.serialize(tabl))
end
