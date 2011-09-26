defineModel = (mongoose, fn) ->
  Schema = mongoose.Schema

  Tag = new Schema(
    long: String
    short:
      type: String
      index: true
      required: true
    type:
      type:     String
      enum:     [ "problem", "user" ]
      required: true
  )

  mongoose.model "Tag", Tag
  fn()

exports.defineModel = defineModel
