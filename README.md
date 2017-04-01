
# bxs

Bundle Exec rSpec

A script to run Rspec in detail.

Given specs that output
```
(...)

Finished in 0.38381 seconds (files took 0.10018 seconds to load)
43 examples, 3 failures, 1 pending

Failed examples:

rspec ./spec/eo_time_spec.rb:540 # EtOrbi::EoTime.make accepts a Date
rspec ./spec/eo_time_spec.rb:562 # EtOrbi::EoTime.make accepts a String (Zulu)
rspec ./spec/eo_time_spec.rb:582 # EtOrbi::EoTime.make accepts a String (ss-01)
```
then
```
bxs 0     # ---> will run bundle exec rspec ./spec/eo_time_spec.rb:540
bxs -1    # ---> will run bundle exec rspec ./spec/eo_time_spec.rb:582
bxs 0 -1  # ---> will run both first and last faulty spec
bxs :540  # ---> will run bundle exec rspec ./spec/eo_time_spec.rb:540

bxs i     # ---> will list the current indexes (the list of shortcuts)
```

There is also
```
bxs r   # ---> reads the while .bxsinfo data and pretty prints it
```


## preparation (installation)

```
 $ cd bin/
bin $ ln -s ~/work/bxs/src/bxs
```


## license

MIT, see [LICENSE.txt](LICENSE.txt)

