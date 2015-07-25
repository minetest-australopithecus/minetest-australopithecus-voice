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
	
	for index = 1, string.len(message) - 2, 1 do
		local piece = string.sub(message, index, 1)
		
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

function voice.speak(speaking_player, message, parameters)
	local source_pos = speaking_player:getpos()
	local name = speaking_player:get_player_name()
	
	for index, player in ipairs(minetest.get_connected_players()) do
		local player_name = player:get_player_name()
		local distance = mathutil.distance(source_pos, player)
		
		if distance <= parameters.understandable then
			minetest.chat_send_player(player_name, "<" .. name .. "> " .. message)
		elseif distance <= parameters.abstruse then
			local rate = transform.linear(distance, parameters.understandable, parameters.abstruse)
			
			if voice.random(rate) then
				minetest.chat_send_player(player_name, "<" .. voice.muffle(name) .. "> " ..  voice.abstruse(message, rate))
			else
				minetest.chat_send_player(player_name, "<" .. name .. "> " .. voice.abstruse(message, rate))
			end
		elseif distance <= parameters.incomprehensible then
			minetest.chat_send_player(player_name, "<" .. voice.muffle(name) .. "> " .. voice.muffle(message))
		end
	end
end

