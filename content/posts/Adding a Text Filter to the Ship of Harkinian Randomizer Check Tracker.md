---
date: 2025-02-03T09:40:26-05:00
description: "computers are better than people at looking through lots of text"
lastmod: 2025-02-03
showTableOfContents: false
tags: ["ship of harkinian", "randomizer", "c++"]
title: "Adding a Text Filter to the Ship of Harkinian Randomizer Check Tracker"
type: "post"
---

# Premise
Back in March of 2024 a friend of mine and I were playing The Legend of Zelda:
Ocarina of Time randomizers using [Ship of
Harkinian](https://www.shipofharkinian.com/), an amazing community project.

![Ship of Harkinian Holiday Edition 2024](/images/check-tracker-thumbnail.png)

A quick note about randomizers. It's often useful to keep track of what things
you've checked. A check is the location of an item, so for example in Ocarina of
Time you start in Kokiri Forest and you can go get the Kokiri Sword from a chest
by crawling through a hole in the wall near your house. In fact the name for
that check in the Ship of Harkinian code is `RC_KF_KOKIRI_SWORD_CHEST`.

So, my friend and I were playing a randomizer cooperatively, made possible by
this [mod](https://github.com/garrettjoecox/anchor), and were talking about how
great it would be if you could filter through the various checks, so you could
quickly find what you were looking for.

# Adding the Feature

So we set out, familiarizing ourselves with the project. It turns out there is
already a pattern for filtering text, the Entrance Tracker has one.

```c++
// commit 69d6631bbc7ccc179d277505529c6e4e11ac79d9
// shipwright/soh/soh/Enhancements/randomizer/randomizer_entrance_tracker.cpp
static ImGuiTextFilter locationSearch;
// ... content removed for brevity
if (ImGui::Button("Clear")) {
    locationSearch.Clear();
}
UIWidgets::Tooltip("Clear the search field");
```

The following is copied from commit `ebee171d2235402ab2de36f557fc48c72b063231`
and all takes place in the
`shipwright/soh/soh/Enhancements/randomizer/randomizer_check_tracker.cpp` file
but fair warning the code has changed upstream since we contributed the feature.

We started by added the UI element.

```c++
static ImGuiTextFilter checkSearch;
if (ImGui::Button("Clear")) {
    checkSearch.Clear();
}
UIWidgets::Tooltip("Clear the search field");
```

Created a helper function to encapsulate the logic of filtering an individual
check. Which checks if either the area the item is in, or the name of the item
itself matches our filter.

```c++
bool passesTextFilter(ImGuiTextFilter& checkSearch, RandomizerCheckObject check) {
    return (
        checkSearch.PassFilter(RandomizerCheckObjects::GetRCAreaName(check.rcArea).c_str()) ||
        checkSearch.PassFilter(check.rcShortName.c_str())
    );
}
```

Finally we applied the helper in the appropriate places
```c++
for (auto rcObject : objs) {
    if (IsVisibleInCheckTracker(rcObject) &&

        // run our filter
        passesTextFilter(checkSearch, rcObject) &&

        doDraw &&
        isThisAreaSpoiled) {
      DrawLocation(rcObject);
    }
}
```

# The Spoils

And here it is in action.

{{< media/video src=/videos/soh-check-tracker.webm type="video/webm" >}}

