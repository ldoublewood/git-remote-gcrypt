-

gcrypt: Enabled: no

gcrypt: ==============================

gcrypt: Received command: capabilities

gcrypt: Received command: list for-push   

gcrypt: Incremental mode enabled for branch: my

gcrypt: Incremental mode detected

gcrypt: Latest remote manifest serial: 0

gcrypt: Listing remote references...

gcrypt: Checking remote connection to: rsync://root@2.2.2.2:/s/tmp/gcrypt-incremental-test

gcrypt: Remote repository status: no

gcrypt: Remote repository not found, returning empty list

gcrypt: Received command: push refs/heads/my:refs/heads/my

gcrypt: Incremental mode enabled for branch: my

gcrypt: Starting incremental push for branch: my

gcrypt: Full push required

gcrypt: No incremental range found, falling back to full push

gcrypt: Falling back to full push

gcrypt: Performing encrypted push

以上是第一次push时的日志，第一次push，远程仓库当然是没有任何commit，但这时也不能转为full push，而是仍以incremental模式进行push，只不过远程仓库要做incremental模式的初始化，例如创建manifest文件等