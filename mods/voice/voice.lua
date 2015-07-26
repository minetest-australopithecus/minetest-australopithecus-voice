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


voice = {
	line_of_sight_mod = 0.40,
	pseudo_random = nil,
	talk_parameters = {
		understandable = 6,
		abstruse = 12,
		incomprehensible = 17
	},
	shout_parameters = {
		understandable = 45,
		abstruse = 60,
		incomprehensible = 80
	},
	whisper_parameters = {
		understandable = 3,
		abstruse = 4,
		incomprehensible = 5
	}
}


function voice.abstruse(message, rate)
	local abstruse_message = ""
	
	for index = 1, string.len(message), 1 do
		local piece = string.sub(message, index, index)
		
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

function voice.activate()
	voice.pseudo_random = PseudoRandom(0)
	
	minetest.register_on_chat_message(voice.on_chat_message)
	
	voice.register_chatcommand("t", "talk", "Talk", voice.talk_parameters)
	voice.register_chatcommand("s", "shout", "Shout", voice.shout_parameters)
	voice.register_chatcommand("w", "whisper", "Whisper", voice.whisper_parameters)
end

function voice.in_range(distance, range, line_of_sight)
	if line_of_sight then
		return distance <= range
	else
		return distance <= (range * voice.line_of_sight_mod)
	end
end

function voice.muffle(message)
	return string.gsub(message, "%w", ".")
end

function voice.on_chat_message(name, message)
	local player = minetest.get_player_by_name(name)
	
	voice.speak(player, message, voice.talk_parameters)
	
	-- Do not send the message further, we've done that.
	return true
end

function voice.random(rate)
	return (voice.pseudo_random:next(0, 100) / 100) <= rate
end

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

function voice.speak(speaking_player, message, parameters)
	local source_pos = speaking_player:getpos()
	local name = speaking_player:get_player_name()
	
	for index, player in ipairs(minetest.get_connected_players()) do
		local target_pos = player:getpos()
		local distance = mathutil.distance(source_pos, target_pos)
		
		-- Test now if we're even in range, minor optimization.
		if distance <= parameters.incomprehensible then
			local player_name = player:get_player_name()
			
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
				minetest.chat_send_player(player_name, "<" .. name .. "> " .. message)
			elseif voice.in_range(distance, parameters.abstruse, line_of_sight) then
				local rate = transform.linear(distance, parameters.understandable, parameters.abstruse)
				
				if voice.random(rate) then
					minetest.chat_send_player(player_name, "<" .. voice.muffle(name) .. "> " ..  voice.abstruse(message, rate))
				else
					minetest.chat_send_player(player_name, "<" .. name .. "> " .. voice.abstruse(message, rate))
				end
			elseif voice.in_range(distanc, parameters.incomprehensible, line_of_sight) then
				minetest.chat_send_player(player_name, "<" .. voice.muffle(name) .. "> " .. voice.muffle(message))
			end
		end
	end
end

