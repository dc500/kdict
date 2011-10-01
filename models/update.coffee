defineModel = (mongoose, fn) ->
  Schema = mongoose.Schema

  Update = new Schema
    entry:
      type:     Schema.ObjectId
      index:    true
      required: true
      ref:      "Entry"

    user:
      type:     Schema.ObjectId
      index:    true
      required: true
      ref:      "User"

    before:
      type: Schema.Types.Mixed
      required: true

    after:
      type: Schema.Types.Mixed
      required: true

    type:
      type: String
      enum: [ "new", "edit", "delete" ]
      required: true

    created_at:
      type:     Date
      default:  Date.now
      required: true
      index:    true

  mongoose.model "Update", Update
  fn()

exports.defineModel = defineModel

