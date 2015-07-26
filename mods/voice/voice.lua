--[[
Copyright (c) 2015, Robert 'Bobby' Zenz
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]


--- Voice is a system to make the chat of Minetest more like a voice.
--
-- The only function that should be called from the client is activate.
voice = {
	--- The line of sight modification, which means that if the target does not
	-- have line of sight with the source, this mod will be applied to
	-- the range to limit it.
	line_of_sight_mod = 0.40,
	
	--- The source for random chances when modifying messages.
	pseudo_random = nil,
	
	--- The parameters for talking.
	talk_parameters = {
		--- Everything within this range (inclusive) will be understandable.
		understandable = 6,
		
		--- Everything within this range (inclusive) will be abstruse, which
		-- means that only part of the message (depending on the distance) will
		-- be understandable.
		abstruse = 12,
		
		--- Everything within this range (inclusive) will not be understandable.
		incomprehensible = 17
	},
	
	--- The parameters for shouting.
	shout_parameters = {
		--- Everything within this range (inclusive) will be understandable.
		understandable = 45,
		
		--- Everything within this range (inclusive) will be abstruse, which
		-- means that only part of the message (depending on the distance) will
		-- be understandable.
		abstruse = 60,
		
		--- Everything within this range (inclusive) will not be understandable.
		incomprehensible = 80
	},
	
	--- The parameters for whispering.
	whisper_parameters = {
		--- Everything within this range (inclusive) will be understandable.
		understandable = 3,
		
		--- Everything within this range (inclusive) will be abstruse, which
		-- means that only part of the message (depending on the distance) will
		-- be understandable.
		abstruse = 4,
		
		--- Everything within this range (inclusive) will not be understandable.
		incomprehensible = 5
	}
}


--- Abstruses the given message. That means that parts of it will be blanked,
-- based on the rate.
--
-- @param message The message to abstruse.
-- @param rate The rate at which to abstruse the message, a value between
-- 0 and 1, with 1 being everything abstrused.
-- @return The abstrused message.
function voice.abstruse(message, rate)
	local abstruse_message = ""
	
	for index = 1, string.len(message), 1 do
		local piece = string.sub(message, index, index)
		
		-- Only abstruse words, leave dots, quotes etc. in place.
		if string.find(piece, "%w") ~= nil then
			if voice.random(rate) then
				abstruse_message = abstruse_message .. "."
			else
				abstruse_message = abstruse_message .. piece
			end
		else
			abstruse_message = abstruse_message .. piece
		end
	end
	
	return abstruse_message
end

--- Activates the voice system.
function voice.activate()
	voice.pseudo_random = PseudoRandom(0)
	
	minetest.register_on_chat_message(voice.on_chat_message)
	
	voice.register_chatcommand("t", "talk", "Talk", voice.talk_parameters)
	voice.register_chatcommand("s", "shout", "Shout", voice.shout_parameters)
	voice.register_chatcommand("w", "whisper", "Whisper", voice.whisper_parameters)
end

--- Checks if the given distance is in the given range, considering
-- the line of sight.
--
-- @param distance The distance.
-- @param range The range.
-- @param line_of_sight If there is line of sight.
-- @return true if it is in range.
function voice.in_range(distance, range, line_of_sight)
	if line_of_sight then
		return distance <= range
	else
		return distance <= (range * voice.line_of_sight_mod)
	end
end

--- Muffles the given messages, meaning replaces everything with dots.
--
-- @param message The message to muffle.
-- @return The muffled message.
function voice.muffle(message)
	-- Replace only words.
	return string.gsub(message, "%w", ".")
end

--- Callback for if a chat message is send.
--
-- @param name The name of the sending player.
-- @param message The message that is send.
-- @return true if the message has been handled and should not be send.
function voice.on_chat_message(name, message)
	local player = minetest.get_player_by_name(name)
	
	voice.speak(player, message, voice.talk_parameters)
	
	-- Do not send the message further, we've done that.
	return true
end

--- Gets a random chance based on the given rate.
--
-- @param rate The rate. A number between 0 and 1, with 1 being always true.
-- @return true if there is a chance.
function voice.random(rate)
	return (voice.pseudo_random:next(0, 100) / 100) <= rate
end

--- Registers a chat chommand.
--
-- @param short The short command.
-- @param long The long command.
-- @param description The description of the command.
-- @param parameters The parameters to use.
function voice.register_chatcommand(short, long, description, parameters)
	local command = {
		description = description,
		params = "<message>",
		func = function(player_name, message)
			local player = minetest.get_player_by_name(player_name)
			
			voice.speak(player, message, parameters)
			
			return true
		end
	}
	
	minetest.register_chatcommand(short, command)
	minetest.register_chatcommand(long, command)
end

--- Speaks the given message.
--
-- @param speaking_player The speaking player, a Player Object.
-- @param message The message that is spoken.
-- @param parameters The speak parameters, like talk_parameters.
function voice.speak(speaking_player, message, parameters)
	local source_name = speaking_player:get_player_name()
	local source_pos = speaking_player:getpos()
	
	for index, player in ipairs(minetest.get_connected_players()) do
		local target_pos = player:getpos()
		local distance = mathutil.distance(source_pos, target_pos)
		
		-- Test now if we're even in range, minor optimization.
		if distance <= parameters.incomprehensible then
			local target_name = player:get_player_name()
			
			-- TODO The y+1 thing is to emulate players height, might be wrong.
			local line_of_sight = minetest.line_of_sight({
				x = source_pos.x,
				y = source_pos.y + 1,
				z = source_pos.z
			}, {
				x = target_pos.x,
				y = target_pos.y + 1,
				z = target_pos.z
			})
			
			if voice.in_range(distance, parameters.understandable, line_of_sight) then
				minetest.chat_send_player(
					target_name,
					"<" .. source_name .. "> " .. message)
			elseif voice.in_range(distance, parameters.abstruse, line_of_sight) then
				local rate = transform.linear(distance, parameters.understandable, parameters.abstruse)
				
				-- Here we have a random chance that the player name is muffeld.
				if voice.random(rate) then
					minetest.chat_send_player(
						target_name,
						"<" .. voice.muffle(source_name) .. "> " ..  voice.abstruse(message, rate))
				else
					minetest.chat_send_player(
						target_name,
						"<" .. source_name .. "> " .. voice.abstruse(message, rate))
				end
			elseif voice.in_range(distanc, parameters.incomprehensible, line_of_sight) then
				minetest.chat_send_player(
					target_name,
					"<" .. voice.muffle(source_name) .. "> " .. voice.muffle(message))
			end
		end
	end
end

