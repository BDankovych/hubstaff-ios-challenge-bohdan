# Hubstaff iOS Recruitment Challenge

Thank you for taking on Hubstaff's iOS recruitment challenge.

We're eager to see what you can do!

Feel free to reach out to anastasiya.mashyna@hubstaff.com or maarten.billemont@hubstaff.com for any questions you might have, or to submit your solutions.


## The Objective

Hubstaff's application helps people work more efficiently and deliver proof of work to faciliate getting paid for every second you put in.

We had nearly completed our implementation when suddenly the whole team was forced to go on retreat.

Can you save the day and wrap up the project in time to salvage our quarterly roadmap?

### Primary Objective (4h)

Complete the user interface of the Timer screen in [TimerScreen.swift](Features/Tracker/TimerScreen.swift) by replacing the TODO comments with your implementation.

The application is written using SwiftUI. Our data flows in using Combine from data methods in our service modules.

All of the data wiring is already in place: we just need you to expose it in the fantastic UI mocked up by our designers:

<img alt="User not tracking time" width="30%" src="https://user-images.githubusercontent.com/36948/184034993-11c20245-f749-477c-8768-adc1bf80e85f.png"><img alt="User now tracking time" width="30%" src="https://user-images.githubusercontent.com/36948/184035060-922ffbea-40bc-4edd-8bec-96c28c885f69.png"><img alt="User now exceeded time" width="30%" src="https://user-images.githubusercontent.com/36948/184035312-f647c541-806a-4bc4-9119-3ea2980e67e4.png">

Requirements:

- Render the Tracker service's state according to the designs:
    - Not tracking time,
    - Tracking work time,
    - Tracking a break,
    - Exceeded available break or work time,
    - Button to start a break, available while tracking work (see Secondary objective),
    - Button to select a project,
    - Button to record a time (pencil) or task (picture) note, available while tracking work,
    - Limit text, time tracked, project tracked, task tracked.
- Following these design guidelines:
    - The title should not exceed 1 line, ellipsize if necessary,
    - The subtitle should not exceed 2 lines, ellipsize if necessary,
    - The text inside the circle should not collide with the circle,
    - The limit text should tint red if exceeded (but not on the red background),
    - Tapping the limit text should bring up a pop-up describing the limit details,
    - The breaks button should dim (30% opacity) if no breaks are available and disable,
    - The breaks button should bring up a popup with available breaks to start.

### Secondary Objective (2h, optional)

Got even more in you? Product would absolutely love it if we could add just one more feature to our deliverable.

You may have noticed that the Service team was unable to complete one feature of the tracker:
The tracker does not yet start tracking against breaks.

If you could, jump in and wire the missing business logic into the `TrackerSampleInteractor`.

<img alt="User now taking a break" width="30%" src="https://user-images.githubusercontent.com/36948/184035418-b4226d5d-5372-4a23-91e4-9d82e91a79a9.png">


### Alternate Objective (optional)

Not a fan of our designs or architecture? Or perhaps you have a novel idea, alternative approach, or sleek design in mind?

That's great! Try and achieve the product goals from the primary objective in your own way! Remove whatever you like and surprise us with something novel!


## Submission

You're the architect here. All the choices are yours.

You have a substantial existing codebase to work in, with an existing architectural model. Everything is well documented!
- Check out [Architecture.swift](Orchestration/Architecture.swift) for an overview of the architecture.
- Documentation on [TrackerInteractor.swift](Services/Tracker/TrackerInteractor.swift) will help you ingest the business data.
- See our [Style.swift](Features/App/Theme/Style.swift) for the standards we have defined; rely on these as much as possible.
- Browse our [Components](Features/App/Theme/Components) to help you ensure a consistent look & feel across our application.
- Take a peek at [More.swift](Features/More/MoreScreen.swift) for some hints on how we organize our view code.
- Visit our `Media` asset catalogue for any graphic assets you may need.

You may notice that we like to use a view model, populated by the presenter, to supply the presentation data to the view.
See if you can adopt this pattern.


### Criteria

We're primarily interested in seeing what you think is the best way to solve the issues you'll run into.
More so than just ticking off all the boxes, we're hoping to receive an app that's healthy and we can build on.

When evaluating your solution, we will judge:
- The clarity and simplicity of your code
- The sustainability of your implementation choices
- Your understanding of, and integration with, existing patterns
- How you communicate your choices with your peers
- Your genuine opinions, thoughts and ideas


### Your Repository

In your cloned repo, please check out a separate branch using your own name.  When you're finished, you'll submit a pull request from this branch back to `main`.

Try and separate out unrelated changes into separate commits. Feel free to use commit messages to describe your choices and let us know what you're thinking.

When you're ready, create a *private* GitHub repo to push your changes into and add the following contributors:
- <a href="https://github.com/lhunath"><strong>lhunath</strong> Maarten Billemont</a>
- <a href="https://github.com/ayarotsky"><strong>ayarotsky</strong> Alex Yarotsky</a>

Now you can create the pull request from your personal branch back to `main` in your GitHub repo, adding the above users as PR reviewers.

Good luck, private!  We're counting on you.
