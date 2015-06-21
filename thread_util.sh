# date: 2015.5.17
# author: sunpengcheng(sunpch@hotmail.com)
# brief: use shell to start multithread and restrict the number of thtread

_THREAD_NUM=0
_THREAD_PIPE_NAME=""
_THREAD_PIPE_ID=100

trap _clean_up SIGINT SIGTERM SIGKILL

function thread_init()
{
	thread_num=$1
	if [ -z "$thread_num" ]; then
		thread_num = $( _get_num_of_cpu_core)
	fi

	_THREAD_NUM=$thread_num
	
	_create_pipe
}

function thread_run()
{
	cmd=$1
	if [ -z "$cmd" ]; then
		echo "please input command to run"
		_delete_pipe	
		exit 1
	fi

	_thread_get
	{
		$cmd
		_thread_post
	}&
}

function thread_wait()
{
	wait
	_delete_pipe
}

function _clean_up()
{
	rm -rf _thread_*
	kill -9 $$
}

function _get_num_of_cpu_cores()
{
	core_num=$(cat /proc/cpuinfo | grep processor | wc -l)
	thread_num=$(expr $core_num - 1)
	
	return $thread_num
}

function _get_uid()
{
	str=$(date '+%Y-%m-%d %H:%M:%S')
	
	str=$(echo $str | md5sum)
	str=${str:10:10}
	
	uid="_thread_"$str
	echo $uid
}

function _create_pipe()
{
	_THREAD_PIPE_NAME=$(_get_uid)

	mkfifo ${_THREAD_PIPE_NAME}
	eval exec "${_THREAD_PIPE_ID}""<>${_THREAD_PIPE_NAME}"

	for ((i=0; i < $_THREAD_NUM; i++))
	do
		echo -ne "\n" 1>&${_THREAD_PIPE_ID}
	done
}

function _delete_pipe()
{
	rm -rf ${_THREAD_PIPE_NAME}
}


function _thread_get()
{
	read -u $_THREAD_PIPE_ID
}

function _thread_post()
{
	echo -ne "\n" 1>&${_THREAD_PIPE_ID}
}

#example
#thread_init 5
#for ((i = 0; i < 20; i++))
#do
#	cmd="./a.out"
#	thread_run "$cmd"
#done
#thread_wait
