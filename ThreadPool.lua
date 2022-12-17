local threadIndex = 100 -- How many threads to pre-allocate
local threads = {}

local _coroutine = coroutine
local coroutine_resume = _coroutine.resume
local coroutine_create = _coroutine.create
local coroutine_yield = _coroutine.yield
local _error = error

local function passer(toRun, ...)
	toRun(...)
end
local function runner(thread)
	while true do
		-- Get function and parameters
		-- Run the function
		-- Passer function is necessary because otherwise lua would put toRun (nil at the start) in memory, then yield, then call nil
		passer(coroutine_yield())

		-- Done, make this thread available
		threadIndex = threadIndex + 1
		threads[threadIndex] = thread
	end
end

for i = 1, threadIndex do
	local thread = coroutine_create(runner)
	coroutine_resume(thread, thread)
	threads[i] = thread
end

return function(func, ...)
	if threadIndex ~= 0 then
		-- Thread available
		local thread = threads[threadIndex]

		-- Remove as available
		threads[threadIndex] = nil
		threadIndex = threadIndex - 1

		local success, errorMessage = coroutine_resume(thread, func, ...)
		if not success then
			_error(errorMessage)
		end
	else
		local thread = coroutine_create(runner)
		coroutine_resume(thread, thread)

		local success, errorMessage = coroutine_resume(thread, func, ...)
		if not success then
			_error(errorMessage)
		end
	end
end
