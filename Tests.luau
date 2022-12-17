--!strict

local run = require(script.Parent.ThreadPool)

-- NON_YIELDING
print("Testing spawning functions that don't yield")

local function blank()

end

local s = os.clock()
for i=1, 1e6 do
	task.spawn(blank)
end
print("task.spawn", os.clock() - s)

local s = os.clock()
for i=1, 1e6 do
	run(blank)
end
print("ThreadPool", os.clock() - s)

-- YIELDING
print("Testing spawning functions that yield")

local function yields()
	task.wait()
end

local s = os.clock()
for i=1, 1e6 do
	task.spawn(yields)
end
print("task.spawn", os.clock() - s)

local s = os.clock()
for i=1, 1e6 do
	run(yields)
end
print("ThreadPool", os.clock() - s)
