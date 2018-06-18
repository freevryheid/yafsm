import yafsm

proc main() =

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
  # states are defined in terms of init,
  # update, draw and exit functions.
  # init and exit are run once,
  # update and draw are run repeately while in state.
  # all are optional.
  # fsm will exit if transitioning to a state without
  # update or draw functions.
  block S1:  # this first state

    s1.init = proc() =
      echo "hello from s1"

    s1.update = proc() =
      echo "updating s1"
      m.trigger(e1)

    s1.exit = proc() =
      echo "bye from s1"

  block S2:  # the second state

    s2.init = proc() =
      echo "hello from s2"
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
      echo "bye from s3"
      m.destroy(e1)

  block S4:  # the fourth state (no update/draw)

    s4.init = proc() =
      echo "hello from  s4"
      m.destroy(e1)

  # register events after states have been defined above
  # indicates transition when triggered:
  e1 = m.register(s1, s2)  # s1 -> s2
  e2 = m.register(s2, s3)  # s2 -> s3
  e3 = m.register(s4)      # * -> s4
  # transitioning to an undefined state (s4.update) stops the machine

  m.start(s1)

when isMainModule:
  main()
