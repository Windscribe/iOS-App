# Release Process for iOS App

This document outlines the steps to follow when releasing the iOS app, including creating a release branch, internal and external TestFlight distribution, QA testing, and final app store submission.

- [ ] Feature Freeze Discussion
 - **Timing:** Prior to the release cycle, schedule a feature freeze discussion with the team.
 - **Objective:** Review all pending features and ensure only necessary changes are pushed to the release branch. Bug fixes are still allowed 
 post-freeze.

- [ ] Create Release Branch
 - **Branching:** Create a release branch from the main branch.
  ```bash
  git checkout -b release-branch-x.x.x
  ```
- [ ] Test all issues locally as much as possible.
- [ ] Send release to internal Qa on Testflight and also change version info.
- [ ] Fix Qa feedback, update release and repeat until full Qa pass is received. 
- [ ] Prepare External Testflight changelog.
- [ ] Release app to External Testflight
- [ ] Fix Users feedback, update release and repeat.
- [ ] Prepare final changelog. Always follow same changelog format as Android/Desktop.
- [ ] Send app for apple review.
- [ ] Distribute app to app store users.
- [ ] Merge release branch in to main
- [ ] Create tag from main branch
 ```bash
  git tag -a vX.X.X -m "Release X.X.X"
  git push origin vX.X.X
```
- [ ] Sync code to github and create a tagged release.
- [ ] Create admin panel release in staging and verify changes on https://www-staging.windscribe.com/
- [ ] Let team lead know to copy release to production admin.
- [ ] For hotfix Create new branch from tag, make fix, test changes, merge in to main branch and create tag for hotfix.
```bash
git checkout -b hotfix-issuenumber-vX.X.X tags/vX.X.X
```
