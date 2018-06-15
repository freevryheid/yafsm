# this is still a work in progress

type
  State* = tuple
    init: (proc())
    update: (proc())
  Event* = tuple
    pre: State
    post: State
  Events = tuple
    event: Event
    armed: bool
  FSM* = object
    state: State
    dummy: State
    events: seq[Events]
    running: bool
    sid, eid: int

method init*(this: var FSM) {.base.} =
  ## initiate the fsm - do this before defining states and registing events
  this.events = @[]
  this.running = true

method set*(this: var FSM, state: State) {.base.} =
  ## sets the current state
  this.state = state
  if this.state.init != nil:
    this.state.init()

method stop*(this: var FSM) {.base.} =
  ## stop the fsm
  this.running = false

method run(this: var FSM) {.base.} =
  while this.running:
    for e in this.events.mitems:
      if e.armed:
        if e.event.pre == this.dummy or e.event.pre == this.state:
          this.set(e.event.post)
          e.armed = false
    if this.state.update != nil:
      this.state.update()
    else:
      this.stop()

method start*(this: var FSM, state: State) {.base.} =
  ## crank up the fsm indicating the start state
  this.set(state)
  this.run()

method trigger*(this: var FSM, event: Event) {.base.} =
  ## trigger event - events are unarmed after triggered
  for e in this.events.mitems:
    if e.event == event:
      e.armed = true
      break

method register*(this: var FSM; s1: State, s2: State = this.dummy): Event {.base.} =
  ## register event indicating state transition
  ## if both s1 and s2 are provided then
  ## states will only transition from s1 -> s2
  ## if current state is s1
  ## if only s1 provided, current state will
  ## always transition to s1 when triggered
  if s2 == this.dummy:
    result = (s2, s1)
  else:
    result = (s1, s2)
  var e: Events
  e.event = result
  e.armed = false
  this.events.add(e)

method destroy*(this: var FSM, event: Event) {.base.} =
  ## destroy obsolete events as these are sequenced
  try:
    for i, e in this.events.mpairs:
      if e.event == event:
        this.events.delete(i)
        break
  except:
    discard

when isMainModule:

  # declare fsm, states and events
  var
    m: FSM
    s1, s2, s3: State
    e1, e2, e3: Event
    counter = 0

  # fsm must be initiated before defining states and registering events
  m.init()

  # states are defined after fsm initiated
  # blocks used here for partitioning only
  # block are not required

  # states are defined in terms of init and update functions
  #
  block S1:  # this first state

    s1.init = proc() =
      echo "initing s1"

    s1.update = proc() =
      echo "updating s1"
      m.trigger(e1)

  block S2:  # the second state

    s2.init = proc() =
      echo "initing s2"
      m.destroy(e1)  # obsolete events can be destroyed

    s2.update = proc() =
      echo "updating s2"
      inc counter
      if counter < 100:
        m.trigger(e2)
      else:
        m.stop()

  block S3:  # the third state (no init)

    s3.update = proc() =
      echo "updating s3"
      m.trigger(e3)

  # register events after states have been defined above
  # indicates transition when triggered:
  e1 = m.register(s3)      #  * -> s3
  e2 = m.register(s2, s3)  # s2 -> s3
  e3 = m.register(s3, s2)  # s3 -> s2

  # transitioning to an undefined state (s4.update) stops the machine

  m.start(s1)
