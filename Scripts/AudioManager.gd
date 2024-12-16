extends Node2D

var num_players:int = 32
var bus:String = "Master"

var available=[]#:Array[AudioStream]  # The available players.
var queue:Array[AudioStream] = []  # The queue of sounds to play.
var positionQueue:Array[Vector2]=[] # where the sound is played

func _ready():
	# Create the pool of AudioStreamPlayer nodes.
	for i in num_players:
		var p=AudioStreamPlayer2D.new()
		add_child(p)
		p.finished.connect(_on_stream_finished.bind(p))
		p.bus=bus
		available=available+[p]
		#print(available)

func _on_stream_finished(stream:AudioStream):
	# When finished playing a stream, make the player available again.
	#print("finished sound")
	available.push_back(stream)

func play(sound:AudioStream,where=Vector2(0,0)):
	#print("started sound")
	queue.push_back(sound)
	positionQueue.push_back(where)

func _process(delta:float):
	# Play a queued sound if any players are available.
	#print(available.size())
	if not queue.is_empty() and not available.is_empty():
		available[0].set_stream(queue.pop_front())
		available[0].position=positionQueue.pop_front()
		#print("played at "+str(available[0].position))
		available[0].play()
		available.pop_front()
