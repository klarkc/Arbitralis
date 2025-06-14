module Node.Activities
  ( Activities
  , createActivities
  ) where

import Node.OpenAI.Activities
  ( countWords
  , frequentWords
  , sentiment
  )
import Workflows (ActivitiesI)

type Activities = Record ActivitiesI

createActivities :: Activities
createActivities =
  { countWords
  , frequentWords
  , sentiment
  }
