--!strict

local threadIndex = 100 -- How many threads to pre-allocate
local threads = table.create(threadIndex)

local toRun
local function passer(...)
	toRun(...)
end
local function runner(thread: thread): never
	while true do
		-- Get function and parameters
		-- Run the function
		-- Passer function is necessary because otherwise luau would put toRun (nil at the start) in memory, then yield, then call nil
		passer(coroutine.yield())

		-- Done, make this thread available
		threadIndex += 1
		threads[threadIndex] = thread
	end
end

for i = 1, threadIndex do
	local thread = coroutine.create(runner)
	coroutine.resume(thread, thread)
	threads[i] = thread
end

return {
	["pcall"] = function<_, params>(func: (params) -> (), ...: params): (boolean, string?)
		if threadIndex ~= 0 then
			-- Thread available
			local thread = threads[threadIndex]

			-- Remove as available
			threads[threadIndex] = nil
			threadIndex -= 1

			toRun = func
			return coroutine.resume(thread, ...)
		else
			local thread = coroutine.create(runner)
			coroutine.resume(thread, thread)

			toRun = func
			return coroutine.resume(thread, ...)
		end
	end,
	["spawn"] = function<_, params>(func: (params) -> (), ...: params): (thread)
		if threadIndex ~= 0 then
			-- Thread available
			local thread = threads[threadIndex]

			-- Remove as available
			threads[threadIndex] = nil
			threadIndex -= 1

			toRun = func
			return task.spawn(thread, ...)
		else
			local thread = coroutine.create(runner)
			coroutine.resume(thread, thread)

			toRun = func
			return task.spawn(thread, ...)
		end
	end
}
