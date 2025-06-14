module Node.Activities
  ( Activities
  , createActivities
  ) where

import Node.OpenAI.Activities
  ( countWords
  , frequentWords
  )
import Workflows (ActivitiesI)

type Activities = Record ActivitiesI

createActivities :: Activities
createActivities =
  { countWords
  , frequentWords
  }
