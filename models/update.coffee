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

    content:
      type: Schema.Types.Mixed
      required: true

    ###
    before:
      type: Schema.Types.Mixed
      required: true

    after:
      type: Schema.Types.Mixed
      required: true
    ###

    revision_num:
      type:     Number
      default:  1
      required: true
      min: 1

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

