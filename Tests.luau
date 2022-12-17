--!strict

local threadPool = require(game:GetService("ServerStorage").ThreadPool)


-- STRAVANT'S IMPLEMENTATION
	-- The currently idle thread to run the next handler on
	local freeRunnerThread = nil

	-- Function which acquires the currently idle handler runner thread, runs the
	-- function fn on it, and then releases the thread, returning it to being the
	-- currently idle one.
	-- If there was a currently idle runner thread already, that's okay, that old
	-- one will just get thrown and eventually GCed.
	local function acquireRunnerThreadAndCallEventHandler(fn, ...)
		local acquiredRunnerThread = freeRunnerThread
		freeRunnerThread = nil
		fn(...)
		-- The handler finished running, this runner thread is free again.
		freeRunnerThread = acquiredRunnerThread
	end

	-- Coroutine runner that we create coroutines of. The coroutine can be 
	-- repeatedly resumed with functions to run followed by the argument to run
	-- them with.
	local function runEventHandlerInFreeThread()
		-- Note: We cannot use the initial set of arguments passed to
		-- runEventHandlerInFreeThread for a call to the handler, because those
		-- arguments would stay on the stack for the duration of the thread's
		-- existence, temporarily leaking references. Without access to raw bytecode
		-- there's no way for us to clear the "..." references from the stack.
		while true do
			acquireRunnerThreadAndCallEventHandler(coroutine.yield())
		end
	end

	local function stravantSpawn(func, ...)
		if not freeRunnerThread then
			freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			-- Get the freeRunnerThread to the first yield
			coroutine.resume(freeRunnerThread)
		end
		task.spawn(freeRunnerThread, func, ...)
	end


-- NON_YIELDING
print("Testing spawning functions that don't yield")

local function blank(params)

end

local s = os.clock()
for i = 1, 1000 do
	task.spawn(blank, i)
end
print("task.spawn", os.clock() - s)

local s = os.clock()
for i = 1, 1000 do
	threadPool(blank, i)
end
print("ThreadPool", os.clock() - s)

local s = os.clock()
for i = 1, 1000 do
	stravantSpawn(blank, i)
end
print("Stravant's", os.clock() - s)

-- YIELDING
print("Testing spawning functions that yield")

local function yields(params)
	task.wait()
end

local s = os.clock()
for i = 1, 1000 do
	task.spawn(yields, i)
end
print("task.spawn", os.clock() - s)

local s = os.clock()
for i = 1, 1000 do
	threadPool(yields, i)
end
print("ThreadPool", os.clock() - s)

local s = os.clock()
for i = 1, 1000 do
	stravantSpawn(yields, i)
end
print("Stravant's", os.clock() - s)
