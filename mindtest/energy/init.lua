-- Sets up the energy network
mindtest.energy = {}

-- Holds the pull functions for each node type
mindtest.energy.energyNodes = {}

local energyNodes = mindtest.energy.energyNodes

local senderGroup = "mindtest:sender"

local receiverGroup = "mindtest:receiver"


-- Registers a node as an energy-carrying node of some type. The pullCB should be
-- a function pullCB(from, to, amountRequested) that returns the amount of energy
-- successfully extracted.
--
-- "from" is the position of the node that requested the energy.
--
-- "to" is the position of the node that received the request, i.e. the node you
-- are writing this callback for.
--
-- "amountRequested" is the amount of energy requested.
--
-- In general you would not use this outside registering new energy nodes.
--
-- Avoid writing this in a way that you could try to pull energy from nodes
-- in a cycle, as that will cause an infinite loop. For example, for nodes that
-- pass energy from other nodes, you can somehow enforce that you never link
-- nodes in a cycle.
function mindtest.register_energy_node(nodename, pullCB)
   energyNodes[nodename] = {}
   energyNodes[nodename].pullCB = pullCB
end


-- This is the function you will generally call to request energy e.g. to
-- fill your magic device's energy buffer. "from" is the position of the
-- source node, and "to" is the position of the target node. It returns
-- the amount of energy successfully obtained.
function mindtest.energy.pull_energy(from, to, amount)
   local fromNodeType = mindtest.get_and_load_node(from).name
   if energyNodes[fromNodeType] then
      return energyNode[fromNodeType].pullCB(from, to, amount)
   else return 0 end
end


-- Some nodes might have a notion of being in a network of explicitly-connected
-- energy-carrying nodes.
--
-- The "mindtest:sender" group describes nodes that can can be linked to send
-- energy to other nodes. The rating describes how far it can send energy.
--
-- The "mindtest:receiver" group describes nodes that can be linked to receive
-- energy from other nodes. Note that the rating can be anything other than 0.
--
-- An example of something that is only a sender would be a generator.
--
-- An example of something that is only a receiver would be a machine that makes
-- dirt from energy.
--
-- An example of something that is both would be any transmission node that passes
-- energy from upstream providers to downstream nodes.
--
-- The sender and receiver groups use the "upstreams" and "downstreams" metadata
-- entries respectively, which store the positions of the nodes immediately upstream
-- and downstream to the node. The construction and destruction of these are handled
-- automatically, so you probably do not want to touch them. The positions are
-- stored in a table where pos strings are the indices. (The table is stored as
-- a serialize string)


local function is_group(group, pos)
   local nodeName = mindtest.get_and_load_node(pos).name
   return minetest.get_item_group(nodeName, group) ~= 0
end


local function is_sender(pos)
   return is_group(senderGroup, pos)
end

local function is_receiver(pos)
   return is_group(receiverGroup, pos)
end

mindtest.energy.is_sender = is_sender
mindtest.energy.is_receiver = is_receiver

local get_meta_table = mindtest.get_meta_table

local set_meta_table = mindtest.set_meta_table

-- Handles the remove of a node from the network
function mindtest.energy.sever_links(pos)

   local posHash = minetest.hash_node_position(pos)

   local meta = minetest.get_meta(pos)
   
   if is_receiver(pos) then

      local upstreams
      local upMeta
      local upDownstreams

      upstreams = get_meta_table(meta, "upstreams") or {}
      
      for upPos, _ in upstreams do
	 upMeta = minetest.get_meta(upPos)

	 upDownstreams = get_meta_table(upMeta, "downstreams")

	 -- Remove the node we're severing from the upstream node's
	 -- downstream list
	 if upDownstreams then
	    upDownstreams[posHash] = nil
	    set_meta_table(upMeta, "downstreams", upDownstreams)
	 end
      end

      meta:set_string("upstreams", nil)
   end

   if is_sender(pos) then
      local downstreams
      local downMeta
      local downUpstreams

      downstreams = get_meta_table(meta, "downstreams") or {}
      
      for downPos, _ in downstreams do
	 downMeta = minetest.get_meta(downPos)

	 downUpstreams = get_meta_table(downMeta, "upstreams")

	 -- Remove the node we're severing from the downstream node's
	 -- upstream list
	 if downUpstreams then
	    downUpstreams[posHash] = nil
	    set_meta_table(downMeta, "upstreams", downUpstreams)
	 end
      end

      meta:set_string("downstreams", nil)
   end
end


-- Links a sender to a receiver. Takes positions.
function mindtest.energy.link_nodes(from, to)

   err = false

   if not is_sender(from) then
      minetest.log("error",
		   "Attempted to link non-sender "..to_string(from).." as sender")
      err = true
   end

   if not is_receiver(to) then
      minetest.log("error",
		   "Attempted to link non-receiver "..to_string(to).." as receiver")
      err = true
   end

   if err then return end


   local fromMeta = minetest.get_meta(from)
   local toMeta = minetest.get_meta(to)

   local fromDownstreams = get_meta_table(fromMeta, "downstreams") or {}
   local toUpstreams = get_meta_table(toMeta, "upstreams") or {}

   local toPosHash = minetest.hash_node_position(to)
   local fromPosHash = minetest.hash_node_position(from)

   fromDownstreams[toPosHash] = true
   toUpstreams[fromPosHash] = true

   set_meta_table(fromMeta, "downstreams", fromDownstreams)
   set_meta_table(toMeta, "upstreams", toUpstreams)
end
