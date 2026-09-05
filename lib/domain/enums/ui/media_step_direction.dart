/// Направление шага: к более новым сообщениям (в списке с reverse:true —
/// это меньший messageIndex, визуально ниже) или к более старым (больший
/// messageIndex, визуально выше). См. комментарий в MessagesList:
/// "Список с reverse: true, поэтому самый старый элемент — последний".
enum MediaStepDirection { newer, older }