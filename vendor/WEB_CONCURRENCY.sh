case $(ulimit -u) in

# Automatic configuration for Gunicorn's Workers setting.

# Standard-1X (+Free, +Hobby) Dyno
256)
  export DYNO_RAM=512
  export WEB_CONCURRENCY=${WEB_CONCURRENCY:-02}
  ;;

# Standard-2X Dyno
512)
  export DYNO_RAM=1024
  export WEB_CONCURRENCY=${WEB_CONCURRENCY:-04}
  ;;

# Performance-M Dyno
16384)
  export DYNO_RAM=2560
  export WEB_CONCURRENCY=${WEB_CONCURRENCY:-08}
  ;;

# Performance-L Dyno
32768)
  export DYNO_RAM=6656
  export WEB_CONCURRENCY=${WEB_CONCURRENCY:-011}
  ;;

esac