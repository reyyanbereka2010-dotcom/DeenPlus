//
//  QuranToolbar.swift
//  Deen+
//

import SwiftUI


struct QuranToolbar: View {

    @Binding var arabicSize: CGFloat
    @Binding var showTranslation: Bool


    var body: some View {


        HStack(spacing: 14) {



            Button {


                if arabicSize > 28 {

                    arabicSize -= 2

                }


            } label: {


                Text("A−")

                    .font(.headline)

                    .frame(
                        width: 48,
                        height: 44
                    )


            }


            .background(

                RoundedRectangle(
                    cornerRadius: 14
                )

                .fill(
                    Color.green.opacity(0.12)
                )

            )






            Text(
                "\(Int(arabicSize))"
            )

            .font(.caption)

            .foregroundStyle(
                .secondary
            )

            .frame(
                width: 35
            )






            Button {


                if arabicSize < 60 {

                    arabicSize += 2

                }


            } label: {


                Text("A+")

                    .font(.headline)

                    .frame(
                        width: 48,
                        height: 44
                    )


            }


            .background(

                RoundedRectangle(
                    cornerRadius: 14
                )

                .fill(
                    Color.green.opacity(0.12)
                )

            )







            Divider()

                .frame(
                    height: 30
                )







            Button {


                showTranslation.toggle()


            } label: {


                Image(
                    systemName:
                        showTranslation
                        ? "globe"
                        : "eye.slash"
                )

                .font(.title3)

                .frame(
                    width: 44,
                    height: 44
                )


            }







            Button {


                // Audio later


            } label: {


                Image(
                    systemName: "headphones"
                )

                .font(.title3)

                .frame(
                    width: 44,
                    height: 44
                )


            }







            Button {


                // Search later


            } label: {


                Image(
                    systemName: "magnifyingglass"
                )

                .font(.title3)

                .frame(
                    width: 44,
                    height: 44
                )


            }



        }


        .padding(.horizontal, 16)

        .padding(.vertical, 10)



        .background(

            Capsule()

                .fill(
                    Color(.systemBackground)
                )

                .shadow(
                    color: .black.opacity(0.15),
                    radius: 10,
                    y: 5
                )

        )



        .padding(.horizontal, 16)

        .padding(.bottom, 10)


    }


}
