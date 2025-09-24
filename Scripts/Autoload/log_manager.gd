extends Node


func _ready() -> void:
	print("")
	pass


func _process(delta: float) -> void:
	pass


func compress_to_string(text: String) -> String:
	var data := text.to_utf8_buffer()
	# 使用 DEFLATE 压缩
	var compressed := data.compress(FileAccess.COMPRESSION_DEFLATE)
	# 转成 Base64 方便粘贴
	return Marshalls.raw_to_base64(compressed)


func decompress_from_string(b64: String) -> String:
	var compressed := PackedByteArray()
	compressed = Marshalls.base64_to_raw(b64)
	# 解压回原文
	var data := compressed.decompress(compressed.size() * 10, FileAccess.COMPRESSION_DEFLATE)
	return data.get_string_from_utf8()
