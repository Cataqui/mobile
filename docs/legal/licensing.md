# Cataquí Mobile licensing decision

**Status:** proposed for legal review

**Decision date:** 2026-07-25

## Decision

License Cataquí-authored material under the
[PolyForm Shield License 1.0.0](../../LICENSE).

This is a **source-available license**, not an Open Source Initiative-approved
open-source license. Cataquí must describe the repository accordingly.

## Why this license

Cataquí needs people to be able to inspect, modify, discuss, test, and
contribute to the client without giving them permission to use the client to
launch a competing product.

PolyForm Shield is a standardized, plain-language license that:

- permits use, modification, and distribution for non-competing purposes;
- defines competition across products, services, interfaces, and technical
  platforms;
- expressly includes competing products offered free of charge;
- includes a patent grant and patent-defense termination;
- has no automatic date on which an old version becomes permissively licensed;
  and
- allows a `Licensor Line of Business:` notice to preserve the restriction if
  the current product is discontinued.

The repository's [NOTICE](../../NOTICE) supplies both the required copyright
notice and the line-of-business notice.

## Options rejected

| Option | Why it does not satisfy Cataquí's requirement |
| --- | --- |
| MIT, BSD, or Apache 2.0 | They allow anyone to launch a proprietary, paid, or free competitor using the code. |
| GPL 3.0 or AGPL 3.0 | Copyleft can require source disclosure, but it still permits competing products and commercial use. |
| SSPL or Elastic License 2.0 | Their managed-service restrictions do not prohibit all competing mobile products. |
| Functional Source License | It converts each release to an open-source license after two years, after which an old version could be used competitively. |
| Business Source License 1.1 | It must convert within four years and therefore cannot provide a permanent restriction. |
| PolyForm Perimeter | It protects against products competing with this software; Shield also protects products the licensor or its affiliates provide using the software. |
| No license / all rights reserved | People could view and fork on GitHub, but would lack clear permission to modify, test, and redistribute contributions. |

## What this protects

The license conditions permission to exercise copyright and covered patent
rights in the repository. A person who copies or modifies Cataquí code to
provide a competitor acts outside the license.

The [trademark policy](../../TRADEMARKS.md) separately prevents the software
license from being mistaken for permission to launch a confusingly branded
fork.

The [Contributor License Agreement](../../CONTRIBUTOR_LICENSE_AGREEMENT.md)
keeps contributor ownership intact while granting the project rights to use,
defend, and relicense the combined work. This avoids relying only on
inbound-equals-outbound terms, which could leave the project without the
flexibility needed to protect or relicense contributor-owned code. A
read-only GitHub Actions check requires the acceptance box, and the pull
request template records the signer's legal name for maintainer review.

## What this cannot protect

- It does not stop a competitor from independently implementing the Cataquí
  product idea without using protected code or assets.
- Publishing source can destroy trade-secret protection for anything disclosed
  in the repository.
- A public license does not replace trademark registration, software
  registration, patent analysis, contributor provenance, or enforcement.
- No license guarantees enforcement in every jurisdiction or factual dispute.

## Repository audit

At the decision date:

- all commits in the repository history identify Ryan Holanda, a Cataquí
  founder, as author;
- the repository had no root license, contribution agreement, or trademark
  policy;
- the locked Dart and Flutter dependency graph was inspected for license files;
- no GPL, AGPL, or MPL dependency was detected;
- the direct runtime dependencies reviewed use permissive MIT, BSD-family, or
  Apache-family terms; and
- third-party dependencies remain under their own terms and are excluded from
  Cataquí's outbound grant.

This is a repository-level compatibility review, not a substitute for a
complete software bill of materials or legal opinion.

## Before merging

Qualified counsel should confirm:

1. the written employment, contractor, and IP-assignment chain supporting
   Ventairy Inc.'s ownership of the existing copyrights and patents;
2. Ventairy Inc.'s exact registered name, jurisdiction, and address for
   enforcement and contributor records;
3. enforceability and any required localization for Brazil and launch markets;
4. the electronic Contributor License Agreement acceptance process; and
5. whether Cataquí should register the software and marks with the relevant
   intellectual-property offices.

The team should also perform a separate public-release review for secrets,
personal data, confidential operational rules, third-party assets, and material
that must remain a trade secret.

## Primary research sources

- [Open Source Initiative — The Open Source Definition](https://opensource.org/osd)
- [PolyForm Shield License 1.0.0](https://polyformproject.org/licenses/shield/1.0.0)
- [PolyForm license comparison](https://polyformproject.org/licenses)
- [Functional Source License 1.1](https://fsl.software/)
- [MariaDB Business Source License 1.1](https://mariadb.com/bsl11/)
- [GitHub Terms — contributions under a repository license](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service#6-contributions-under-repository-license)
- [Harmony Contributor Agreement Template 1.0](https://www.harmonyagreements.org/docs/ha-combined-v1)
- [Brazilian Software Law — Lei 9.609/1998](https://www.planalto.gov.br/ccivil_03/leis/l9609.htm)
- [Brazilian Copyright Law — Lei 9.610/1998](https://www.planalto.gov.br/ccivil_03/leis/l9610.htm)
- [INPI software protection guidance](https://www.gov.br/inpi/pt-br/acesso-a-informacao/perguntas-frequentes/programas-de-computador)
