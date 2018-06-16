type
  State* = tuple
    init: proc()
    update: proc()
    draw: proc()
    exit: proc()
  Event* = tuple
    pre: State
    post: State
  Events = tuple
    event: Event
    armed: bool
  FSM* = object
    state: State
    events: seq[Events]
    deli: seq[int]
    running: bool

method init*(this: var FSM) {.base.} =
  ## Initiate the fsm - do this before defining states and registing events.
  this.events = @[]
  this.deli = @[]
  this.running = true

method set*(this: var FSM, state: State) {.base.} =
  ## Sets the current state.
  if this.state.exit != nil:
    this.state.exit()
  this.state = state
  if this.state.init != nil:
    this.state.init()

method stop*(this: var FSM) {.base.} =
  ## Stop the FSM.
  this.running = false

method run(this: var FSM) {.base.} =
  while this.running:
    for e in this.events.mitems:
      if e.armed:
        if e.event.pre == e.event.post or e.event.pre == this.state:
          this.set(e.event.post)
          e.armed = false
    while len(this.deli) > 0:
      this.events.delete(this.deli.pop())
    if this.state.update != nil:
      this.state.update()
    elif this.state.draw != nil:
      this.state.draw()
    else:
      this.stop()

method start*(this: var FSM, state: State) {.base.} =
  ## Start the FSM indicating the first state.
  this.set(state)
  this.run()

method trigger*(this: var FSM, event: Event) {.base.} =
  ## Trigger event - events are unarmed on occurance.
  for e in this.events.mitems:
    if e.event == event:
      e.armed = true
      break

method register*(this: var FSM; s1, s2: State): Event {.base.} =
  ## Register event indicating state transition.
  ## If both s1 and s2 are provided then
  ## states will only transition from s1 -> s2
  ## and only if current state is s1.
  result = (s1,s2)
  var e: Events
  e.event = result
  e.armed = false
  this.events.add(e)

method register*(this: var FSM; s1: State): Event {.base.} =
  ## If only s1 provided, current state will
  ## always transition to s1 when triggered.
  result = (s1, s1)
  var e: Events
  e.event = result
  e.armed = false
  this.events.add(e)

method destroy*(this: var FSM, event: Event) {.base.} =
  ## Destroy obsolete events as these are sequenced.
  ## This marks them for deletion in the run loop.
  for i, e in this.events.mpairs:
    if e.event == event:
      this.deli.add(i)
      break

when isMainModule:

  # declare fsm, states and events
  var
    m: FSM
    s1, s2, s3, s4: State
    e1, e2, e3: Event
    counter = 0

  # fsm must be initiated before defining states and registering events
  m.init()

  # states are defined after fsm initiated
  # blocks used here for partitioning only
  # block are not required
  # states are defined in terms of init and update functions
  block S1:  # this first state

    s1.init = proc() =
      echo "initing s1"

    s1.update = proc() =
      echo "updating s1"
      m.trigger(e1)

    s1.exit = proc() =
      echo "bye from s1"

  block S2:  # the second state

    s2.init = proc() =
      echo "initing s2"
      #m.destroy(e1)  # obsolete events can be destroyed

    s2.update = proc() =
      echo "updating s2"
      inc counter
      echo "counter: ", counter
      if counter >= 5:
        m.trigger(e2)

  block S3:  # the third state (no init)

    s3.update = proc() =
      echo "updating s3"
      m.trigger(e3)

    s3.exit = proc() =
      echo "exiting s3"
      m.destroy(e1)

  block S4:  # the fourth state (no update)

    s4.init = proc() =
      echo "initing s4"
      m.destroy(e1)

  # register events after states have been defined above
  # indicates transition when triggered:
  e1 = m.register(s1, s2)  # s1 -> s2
  e2 = m.register(s2, s3)  # s2 -> s3
  e3 = m.register(s4)      # * -> s4
  # transitioning to an undefined state (s4.update) stops the machine

  m.start(s1)
