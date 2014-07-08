Node = function (_data, _link)

    local setNext = function (link)
        _link = link
    end

    local getNext = function ()
        return _link
    end

    local setData = function (data)
        _data = data
    end

    local getData = function ()
        return _data
    end

    return {
        setNext = setNext,
        getNext = getNext,
        setData = setData,
        getData = getData
    }
end

-- goal is to make an adjacency list, but I can't remember what those are like
-- an array of n linked lists, each node represents an adjacency? It should
-- contain data like { x, y, n } where n is the index of the adjacent vertex
-- and x, y are data? Then it links to the next adjacency? I think that's
-- right. So actually, we aren't representing a graph in memory. OK?
LinkedList = function ()
    local head   = nil
    local tail   = nil
    local length = 0
    local self = {}

    -- iterator should have "hasNext" and "next"
    local getIterator = function ()
        -- an imaginary node pointing at the head
        local p = Node(nil, head)

        local getNext = function ()
            local n = p.getNext()
            p = n

            return n
        end

        local hasNext = function ()
            return p.getNext() ~= nil
        end

        return {
            hasNext = hasNext,
            getNext = getNext
        }
    end

    -- append to the list
    local _append = { }
    _append.func = function (data)
        head   = Node(data, nil)
        tail   = head
        length = 1

        _append.func = function (data)
            local n = Node(data, nil)
            length = length + 1

            tail.setNext(n)
            tail = n
        end
    end

    local getLength = function ()
        return length
    end

    local append = function (data)
        _append.func(data)

        return self
    end

    local prepend = function (data)
        _prepend.func(data)

        return self
    end

    local pop = function ()
        return _pop.func()
    end

    local each = function (callback)
        local iterator = getIterator()
        local index = 0

        while (iterator.hasNext()) do
            local node = iterator.getNext()
            index = index + 1

            callback(node, index)
        end
    end

    self.getLength   = getLength
    self.getIterator = getIterator
    self.append      = append
    self.prepend     = prepend
    self.pop         = pop
    self.each        = each

    return self
end

-- returns an empty queue
Queue = function ()
    local list = LinkedList()
    local self = {}

    local enqueue = function (value)
        list.prepend(value)

        return self
    end

    local dequeue = function ()
        return list.pop()
    end

    self.enqueue = enqueue
    self.dequeue = dequeue
    self.getLength = list.getLength

    return self
end


if DEBUG == true then
    print("NODE DIAGNOSTICS")
    local a, b, p, l, i, data, count, did_run, q

    -- can create a node
    a = Node({ stuff = "hey", nil })
    assert(a.getData() ~= nil)
    assert(a.getNext() == nil)

    -- can set the link to another node
    a.setNext(Node({ stuff = "nil", nil }))
    assert(a.getData() ~= nil)
    assert(a.getNext() ~= nil)
    assert(a.getNext().getData() ~= nil)
    assert(a.getNext().getNext() == nil)

    -- can set the data
    b = a.getNext()
    data = { stuff = "wat" }
    b.setData(data)
    assert(b.getData() == data)

    -- can set the link to another node
    b.setNext(a)
    assert(b.getNext() == a)

    -- doing so creates a loop
    p = a

    count = 0
    while (p ~= nil and count < 4) do
        p = p.getNext()
        count = count + 1
    end

    assert(count == 4)

    print("LINKED LIST DIAGNOSTICS")

    l = LinkedList()
    i = l.getIterator()

    -- can create an empty linked list
    assert(i ~= nil)
    assert(not i.hasNext())
    assert(i.getNext() == nil)

    -- can append 3 elements to a linked list
    l.append(0).append(1).append(2)
    assert(l.getLength() == 3)

    -- can iterate a linked list
    i = l.getIterator()
    count = 0

    while(i.hasNext()) do
        local n = i.getNext()
        assert(n.getData() == count)
        count = count + 1
    end

    -- linkedlist#each iterates the list
    i = l.getIterator()
    count = 0
    did_run = false

    l.each(function (node, index)
        did_run = true
        count = count + 1
        assert(count == index)
        assert(node ~= nil)
        assert(i.getNext() == node)
    end)

    assert(did_run)

    -- can prepend elements to the front of the list
    l.prepend(0).prepend(1).prepend(2)
    assert(l.getLength() == 3)

    -- elements appear in the list in reverse order
    i = l.getIterator()
    count = 2

    while(i.hasNext()) do
        local n = i.getNext()
        assert(n.getData() == count)
        count = count - 1
    end

    -- can pop elements from the back of the list
    iassert(l.pop() == 0)
    assert(l.getLength() == 2)

    print("LINKED LISTS ALL PASS")

    print("TESTS FOR QUEUE")

    q = Queue()
    q.enqueue(1).enqueue(2).enqueue(3)
    assert(q.getLength() == 3)
    assert(q.dequeue() == 1)
    assert(q.dequeue() == 2)
    assert(q.dequeue() == 3)
    assert(q.getLength() == 0)

    print("QUEUE ALL PASS")
end
