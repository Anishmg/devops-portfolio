# Mobile App CI/CD — iOS + Android

## Problem

The platform ships a mobile app on **both** iOS and Android. Building, signing, and
publishing mobile apps by hand is slow, easy to get wrong, and depends on carefully
managed signing material (certificates, provisioning profiles, keystores). It needed
to be automated and repeatable.

> The mobile app is built by the development team. What's documented here is the
> **build, signing, and release automation** I set up around it — the DevOps layer.

## Approach — automated pipelines for both platforms

I built CI/CD so a release goes from commit to store-ready artifact without manual
build steps:

### Android (Flutter)
- Automated the Flutter build in CI.
- Managed the signing keystore securely (injected at build time, never committed).
- Produced signed release artifacts and automated the store deployment path.

### iOS (Xcode)
- Automated the Xcode build.
- Handled Apple signing material — certificates and provisioning profiles — pulled
  from secure storage at build time rather than living on anyone's laptop.
- Produced signed builds for store submission.

## Handling signing material safely

The sensitive part of mobile CI/CD is the signing identity. The pipeline pulls
certificates, provisioning profiles, and keystores from secure storage at build
time and never persists them in the repo or in logs — so releases are reproducible
and the signing material stays controlled.

## What this demonstrates

Cross-platform mobile release automation, secure handling of code-signing material,
and removing manual, error-prone steps from the release process.

**Tech:** GitHub Actions, Flutter (Android), Xcode (iOS), code signing (keystore /
certificates / provisioning profiles)
