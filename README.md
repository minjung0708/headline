# 밀리의 서재 사전 과제 - 헤드라인 앱
### iOS 개발자 권민정

<br>

## 프로젝트 구성
해당 프로젝트는 `Swift`로 작성되었으며, `SwiftUI`, `Combine`과 `MVVM` 패턴 조합으로 데이터와 뷰를 구성하고 있습니다.

기본적으로 뷰는 대부분 `SwiftUI`를 사용하고 있지만, 일부 뷰는 `UIKit`을 사용하여 구현했습니다.

네트워크 통신을 위해 `Alamofire`를, 로컬 데이터 저장을 위해 `Realm`을 사용했습니다.

그 외에는 기본적으로 내장되어있는 라이브러리를 사용했습니다.

최소 지원 os 버전에 대해서는 언급된 바가 없어서 현재 밀리의 서재 지원 버전과 동일한 ***iOS 15.0***으로 설정했습니다.

<br>

## 애플리케이션 사용법

해당 프로젝트는 실물 기기와 시뮬레이터에서 사용할 수 있습니다.

최초 빌드 시에는 서드 파티 라이브러리를 추가해야 하므로 터미널에서 프로젝트 폴더로 이동 후 `pod install` 명령어를 입력해 주세요.

**신뢰하지 않는 개발자** 팝업이 뜬다면 '설정 -> 일반 -> VPN 및 기기 관리 -> 개발자 앱'에서 `kwon.minjung@lotte.net` 신뢰 허용을 눌러주세요.

<br>

- 앱을 최초 실행하면 https://newsapi.org/v2/top-headlines api를 호출하여 데이터를 불러옵니다.
  - 이때, 최초 기본 설정 국가는 **kr** 입니다.
> Api Key는 private한 정보로, github에 업로드 되는 것을 방지하기 위해 **Info.plist**에 저장 후, gitignore를 설정하여 git 업로드 대상에서 제외하였습니다.
- api 호출 결과 데이터가 존재하면 뉴스 헤드라인 리스트가 보여집니다.
- 데이터가 없을 경우 데이터가 존재하지 않는다는 안내 화면이 보여집니다.

<kbd><img src="https://github.com/user-attachments/assets/4f60ebd6-b9e1-4750-ae13-b518e0fa933c" width="300"/></kbd>

> 국가 정보를 **kr**로 설정하면 api 결과값이 존재하지 않아, 리스트를 보여주기 위해 **us**를 추가로 호출할 수 있도록 개발했습니다.
> 
> 우측 상단 국기 모양의 버튼을 터치하면 국가를 한국 <-> 미국 으로 전환하여 각국의 뉴스 헤드라인을 조회할 수 있습니다.
> 
> 아이콘 모양이 현재 호출된 데이터의 `country` 파라미터 값입니다.

- 설정 국가가 **kr**일 때는 데이터가 존재하지 않으므로 아이콘을 터치해 국가를 **us**로 변경하면 다음과 같이 헤드라인 리스트를 확인할 수 있습니다.

<kbd><img src="https://github.com/user-attachments/assets/92dc04e3-1ac6-4c79-b980-16f781220aff" width="300"/></kbd>

- 네비게이션 바의 괄호 안의 숫자는 **해당 국가의 뉴스 헤드라인 전체 개수**입니다.
- 호출된 데이터는 ***Realm***을 사용하여 로컬에 저장됩니다.
  - 이때, 로컬에 항상 최신 데이터를 유지하기 위해 api call 성공 후에는 기존 데이터를 모두 삭제한 뒤, 새로운 데이터를 저장하는 방식을 취했습니다.
  - api 호출에 실패하거나, 오프라인 상태일 경우 자동으로 로컬에 저장된 데이터를 불러옵니다.
- 단, 다른 데이터는 모두 Realm을 통해 로컬에 저장되지만, 이미지는 `UIImage`로 변환된 뒤 다시 `png`파일로 변환되어 기기의 `home directory`에 저장됩니다.
  - 만약 새로 호출한 api 데이터의 이미지가 로컬에 저장된 이미지와 같다면 로컬에 저장된 이미지를 사용합니다.
- 데이터 하나를 선택해 터치하면 해당 기사의 상세 화면으로 이동합니다.

<kbd><img src="https://github.com/user-attachments/assets/c1150eda-9ac4-45c2-ab47-165f9634cb0e" width="300"/></kbd>

- 다시 이전 화면으로 이동시, 방금 전 이동했던 기사의 타이틀 글자색이 **붉은색**으로 변경됩니다.

<kbd><img src="https://github.com/user-attachments/assets/ec9c70e9-1393-462b-8eeb-0aea73a87ce6" width="300"/></kbd>

- 방문한 기사 정보는 `UserDefaults`에 `[기사 URL: 현재 시간]` 형태로 저장됩니다.
  - 단, 기사 URL이 Key로 사용되기 때문에, api에서 제공하는 url 중 삭제된 기사를 표현하는 공통 url인 'https://removed.com/'이 Key로 사용되게 됩니다.
  - 그렇기 때문에 데이터 중 삭제된 기사가 1개 이상이라면, 해당 셀이 아닌 다른 셀의 기사 제목도 붉게 표시될 수 있습니다.
- 해당 프로젝트는 **Portrait**과 **Landscape**를 모두 지원합니다.

<kbd><img src="https://github.com/user-attachments/assets/940e422e-792c-486a-b086-928f74c9cf86" height="300"/></kbd>

<br>

## 추가 구현

### 무한 스크롤
- 해당 프로젝트에서는 성능을 고려하여 ***한번에 20개의 데이터만*** 불러오도록 설정했습니다.
- 따라서 괄호 안의 숫자가 **37**이어도 최초에 표시되는 데이터의 개수는 **20개** 입니다.
- 스크롤을 내려 가장 마지막 아이템에 도달하면 다음 20개의 데이터를 추가로 호출합니다.

### Color Theme
- 해당 프로젝트는 **Light모드**와 **Dark모드** 모두 지원합니다.

<kbd><img src="https://github.com/user-attachments/assets/92dc04e3-1ac6-4c79-b980-16f781220aff" width="300"/></kbd>
<kbd><img src="https://github.com/user-attachments/assets/be9764df-c3cf-4327-aa96-978429bf8dcb" width="300"/></kbd>

### Toast Message
- 안내 문구를 표시하기 위해 Toast View를 구현했습니다.
- 해당 프로젝트에서는 api 호출에 실패했을 때 하단에 Toast View가 표시됩니다.

<kbd><img src="https://github.com/user-attachments/assets/986cb948-a947-4898-9d15-261f8d9202d9" width="300"/></kbd>

<br>

---

<br>

> 기타 궁금한 사항이나 문의, 오류 보고는 <pow2267@gmail.com> 으로 연락바랍니다.
> 
> ***감사합니다.***





