class_name CraftingResult
extends RefCounted
## The outcome of validating or crafting a request.

var ok: bool = false
## Why a request is not valid, in words the crafting screen can show. Empty when ok.
var reason: String = ""
## The spell the request builds. Set whenever it can be previewed, even if the request is not
## valid yet, so the screen can still show the numbers.
var spell: SpellData
